const assert = require('node:assert/strict');
const { after, test } = require('node:test');

const { createServer } = require('./server');

const servers = [];

after(async () => {
  await Promise.all(
    servers.map(
      (server) =>
        new Promise((resolve, reject) => {
          server.close((error) => (error ? reject(error) : resolve()));
        }),
    ),
  );
});

function startServer(options) {
  const server = createServer(options);
  servers.push(server);
  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      resolve(`http://127.0.0.1:${server.address().port}`);
    });
  });
}

test('proxies and caches a season response with an allowed CORS origin', async () => {
  let upstreamRequests = 0;
  let upstreamUrl;
  const baseUrl = await startServer({
    fetchImpl: async (url) => {
      upstreamRequests++;
      upstreamUrl = url.toString();
      return {
        ok: true,
        text: async () => '<results><game /></results>',
      };
    },
  });

  for (let index = 0; index < 2; index++) {
    const response = await fetch(
      `${baseUrl}/euroleague/results?seasoncode=E2026`,
      { headers: { Origin: 'http://localhost:5173' } },
    );
    assert.equal(response.status, 200);
    assert.equal(
      response.headers.get('access-control-allow-origin'),
      'http://localhost:5173',
    );
    assert.match(await response.text(), /<results>/);
  }

  assert.equal(upstreamRequests, 1);
  assert.equal(
    upstreamUrl,
    'https://api-live.euroleague.net/v1/results?seasoncode=E2026',
  );
});

test('rejects unsupported routes, origins, and season codes', async () => {
  let upstreamRequests = 0;
  const baseUrl = await startServer({
    allowedOrigins: ['https://courtiq.example'],
    fetchImpl: async () => {
      upstreamRequests++;
      throw new Error('Must not fetch for invalid requests.');
    },
  });

  const badOrigin = await fetch(
    `${baseUrl}/euroleague/results?seasoncode=E2026`,
    { headers: { Origin: 'https://attacker.example' } },
  );
  assert.equal(badOrigin.status, 403);

  const badSeason = await fetch(
    `${baseUrl}/euroleague/results?seasoncode=U2026`,
    { headers: { Origin: 'https://courtiq.example' } },
  );
  assert.equal(badSeason.status, 400);

  const badRoute = await fetch(`${baseUrl}/proxy?url=https://example.com`);
  assert.equal(badRoute.status, 404);
  assert.equal(upstreamRequests, 0);
});
