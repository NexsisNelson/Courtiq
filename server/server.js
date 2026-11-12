const http = require('node:http');
const { URL } = require('node:url');

const upstreamUrl = 'https://api-live.euroleague.net/v1/results';
const cacheDurationMs = 10 * 60 * 1000;

function createHandler({
  fetchImpl = globalThis.fetch,
  allowedOrigins = (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  cacheDuration = cacheDurationMs,
} = {}) {
  const allowedOriginSet = new Set(allowedOrigins);
  const cache = new Map();

  return async function handleRequest(request, response) {
    const requestUrl = new URL(request.url, 'http://localhost');
    if (requestUrl.pathname !== '/euroleague/results') {
      return sendJson(response, 404, { error: 'Not found.' });
    }

    const origin = request.headers.origin;
    if (origin && !isAllowedOrigin(origin, allowedOriginSet)) {
      return sendJson(response, 403, { error: 'Origin not allowed.' });
    }

    response.setHeader('Vary', 'Origin');
    if (origin) {
      response.setHeader('Access-Control-Allow-Origin', origin);
    }

    if (request.method === 'OPTIONS') {
      response.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
      response.setHeader('Access-Control-Allow-Headers', 'Accept');
      response.setHeader('Access-Control-Max-Age', '600');
      response.writeHead(204);
      return response.end();
    }

    if (request.method !== 'GET') {
      response.setHeader('Allow', 'GET, OPTIONS');
      return sendJson(response, 405, { error: 'Method not allowed.' });
    }

    const seasonCode = requestUrl.searchParams.get('seasoncode');
    if (!/^E20\d{2}$/.test(seasonCode || '')) {
      return sendJson(response, 400, { error: 'Invalid EuroLeague season code.' });
    }

    try {
      const xml = await getSeasonResults(
        seasonCode,
        cache,
        fetchImpl,
        cacheDuration,
      );
      response.writeHead(200, {
        'Cache-Control': `public, max-age=${Math.floor(cacheDuration / 1000)}`,
        'Content-Type': 'application/xml; charset=utf-8',
      });
      return response.end(xml);
    } catch (error) {
      const status = error.name === 'TimeoutError' ? 504 : 502;
      return sendJson(response, status, {
        error: 'The EuroLeague results service is unavailable.',
      });
    }
  };
}

async function getSeasonResults(seasonCode, cache, fetchImpl, cacheDuration) {
  const cached = cache.get(seasonCode);
  const now = Date.now();
  if (cached && cached.expiresAt > now) {
    return cached.promise ?? cached.xml;
  }

  const url = new URL(upstreamUrl);
  url.searchParams.set('seasoncode', seasonCode);
  const pending = {
    expiresAt: now + cacheDuration,
    promise: fetchImpl(url, {
      headers: { Accept: 'application/xml' },
      signal: AbortSignal.timeout(15_000),
    }).then(async (upstreamResponse) => {
      if (!upstreamResponse.ok) {
        throw new Error(`Upstream returned ${upstreamResponse.status}.`);
      }
      const xml = await upstreamResponse.text();
      if (!xml.trim()) {
        throw new Error('Upstream returned an empty response.');
      }
      return xml;
    }),
  };
  cache.set(seasonCode, pending);

  try {
    const xml = await pending.promise;
    cache.set(seasonCode, { expiresAt: Date.now() + cacheDuration, xml });
    return xml;
  } catch (error) {
    if (cache.get(seasonCode) === pending) {
      cache.delete(seasonCode);
    }
    throw error;
  }
}

function isAllowedOrigin(origin, allowedOrigins) {
  if (allowedOrigins.has(origin)) return true;
  try {
    const parsedOrigin = new URL(origin);
    return (
      parsedOrigin.protocol === 'http:' &&
      (parsedOrigin.hostname === 'localhost' ||
        parsedOrigin.hostname === '127.0.0.1')
    );
  } catch {
    return false;
  }
}

function sendJson(response, status, body) {
  response.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(body));
}

function createServer(options) {
  return http.createServer(createHandler(options));
}

if (require.main === module) {
  const port = Number(process.env.PORT || 8787);
  createServer().listen(port, '0.0.0.0', () => {
    console.log(`CourtIQ EuroLeague proxy listening on port ${port}.`);
  });
}

module.exports = { createHandler, createServer };
