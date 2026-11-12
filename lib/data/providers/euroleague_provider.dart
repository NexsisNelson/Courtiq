import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import '../models/game.dart';
import '../services/basketball_data_provider.dart';

class EuroLeagueDataProvider implements BasketballDataProvider {
  EuroLeagueDataProvider({
    Dio? dio,
    DateTime Function()? clock,
    String? baseUrl,
  }) : _dio = dio ?? Dio(),
       _clock = clock ?? DateTime.now,
       _baseUrl = baseUrl ?? _defaultBaseUrl {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.headers['Accept'] = 'application/xml';
  }

  static const _cacheDuration = Duration(minutes: 10);
  static const _webProxyBaseUrl = String.fromEnvironment(
    'EUROLEAGUE_PROXY_BASE_URL',
    defaultValue: 'http://localhost:8787/euroleague',
  );
  static final _inputDateFormat = DateFormat('MMM d, yyyy', 'en_US');
  static final _outputDateFormat = DateFormat('yyyy-MM-dd');

  final Dio _dio;
  final DateTime Function() _clock;
  final String _baseUrl;
  final Map<int, _CachedSeason> _seasonCache = {};

  static String get _defaultBaseUrl => kIsWeb
      ? _webProxyBaseUrl
      : 'https://api-live.euroleague.net/v1';

  @override
  String? get attribution => 'Data powered by EuroLeague';

  @override
  Future<List<Game>> getGames({String? league}) async {
    if (league != null && league != 'EuroLeague') {
      throw BasketballDataException(
        'The EuroLeague provider cannot load $league games.',
      );
    }
    return _sortNewestFirst(await _gamesForSeason(_seasonFor(_clock())));
  }

  @override
  Future<List<Game>> getTeamGames(
    String teamId, {
    required DateTime beforeDate,
  }) async {
    _ensureTeamId(teamId);
    final season = _seasonFor(beforeDate);
    final currentGames = await _gamesForSeason(season);
    final recent = _completedGamesBefore(
      currentGames.where((game) => _hasTeam(game, teamId)),
      beforeDate,
    );
    if (recent.length >= 5) {
      return recent.take(5).toList(growable: false);
    }

    final previousGames = await _gamesForSeason(season - 1);
    return _sortNewestFirst([
      ...recent,
      ..._completedGamesBefore(
        previousGames.where((game) => _hasTeam(game, teamId)),
        beforeDate,
      ),
    ]).take(5).toList(growable: false);
  }

  @override
  Future<List<Game>> getHeadToHeadGames({
    required String homeTeamId,
    required String awayTeamId,
    required DateTime beforeDate,
  }) async {
    _ensureTeamId(homeTeamId);
    _ensureTeamId(awayTeamId);
    if (homeTeamId == awayTeamId) {
      throw const BasketballDataException(
        'A head-to-head lookup requires two different teams.',
      );
    }

    final firstSeason = _seasonFor(beforeDate);
    final seasons = await Future.wait(
      List.generate(
        5,
        (index) => _gamesForSeason(firstSeason - index),
      ),
    );
    return _sortNewestFirst(
      seasons.expand((games) => games).where(
        (game) =>
            game.isFinal &&
            _isBefore(game, beforeDate) &&
            ((game.homeTeamId == homeTeamId &&
                    game.visitorTeamId == awayTeamId) ||
                (game.homeTeamId == awayTeamId &&
                    game.visitorTeamId == homeTeamId)),
      ),
    );
  }

  Future<List<Game>> _gamesForSeason(int season) async {
    final cached = _seasonCache[season];
    final now = DateTime.now();
    if (cached != null && cached.expiresAt.isAfter(now)) {
      if (cached.games != null) return cached.games!;
      if (cached.inFlight != null) return cached.inFlight!;
    }

    final request = _fetchSeason(season);
    final pending = _CachedSeason(
      inFlight: request,
      expiresAt: now.add(_cacheDuration),
    );
    _seasonCache[season] = pending;

    try {
      final games = await request;
      _seasonCache[season] = _CachedSeason(
        games: List.unmodifiable(games),
        expiresAt: DateTime.now().add(_cacheDuration),
      );
      return games;
    } catch (_) {
      if (identical(_seasonCache[season], pending)) {
        _seasonCache.remove(season);
      }
      rethrow;
    }
  }

  Future<List<Game>> _fetchSeason(int season) async {
    try {
      final response = await _dio.get<String>(
        '/results',
        queryParameters: {'seasoncode': 'E$season'},
      );
      final xml = response.data;
      if (xml == null || xml.isEmpty) {
        throw const BasketballDataException(
          'EuroLeague returned an empty season response.',
        );
      }

      final document = XmlDocument.parse(xml);
      if (document.rootElement.name.local != 'results') {
        throw const BasketballDataException(
          'Unexpected response from the EuroLeague results API.',
        );
      }
      return document.findAllElements('game').map(_parseGame).toList();
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        throw const BasketballDataException(
          'The EuroLeague results service is rate limiting requests. Try again later.',
        );
      }
      throw BasketballDataException(
        'Could not load EuroLeague results: '
        '${error.message ?? 'network request failed'}.',
      );
    } on XmlException catch (error) {
      throw BasketballDataException(
        'Could not parse EuroLeague results: $error',
      );
    } on FormatException catch (error) {
      throw BasketballDataException(
        'EuroLeague returned an invalid game date: $error',
      );
    }
  }

  Game _parseGame(XmlElement element) {
    String field(String name) =>
        element.getElement(name)?.innerText.trim() ?? '';

    final gameId = field('gamecode');
    final homeTeamId = field('homecode');
    final awayTeamId = field('awaycode');
    final dateText = field('date');
    final played = field('played').toLowerCase() == 'true';
    final homeScore = int.tryParse(field('homescore'));
    final awayScore = int.tryParse(field('awayscore'));

    if (gameId.isEmpty ||
        homeTeamId.isEmpty ||
        awayTeamId.isEmpty ||
        dateText.isEmpty ||
        field('hometeam').isEmpty ||
        field('awayteam').isEmpty ||
        (played && (homeScore == null || awayScore == null))) {
      throw const BasketballDataException(
        'EuroLeague returned a game with missing required fields.',
      );
    }

    final date = _inputDateFormat.parseStrict(dateText);
    return Game(
      id: gameId,
      date: _outputDateFormat.format(date),
      homeTeamScore: homeScore ?? 0,
      visitorTeamScore: awayScore ?? 0,
      homeTeamName: field('hometeam'),
      visitorTeamName: field('awayteam'),
      homeTeamId: homeTeamId,
      visitorTeamId: awayTeamId,
      status: played ? 'Final' : 'Scheduled',
    );
  }

  List<Game> _completedGamesBefore(
    Iterable<Game> games,
    DateTime beforeDate,
  ) {
    return _sortNewestFirst(
      games.where((game) => game.isFinal && _isBefore(game, beforeDate)),
    );
  }

  List<Game> _sortNewestFirst(Iterable<Game> games) {
    return games.toList()..sort((first, second) => second.date.compareTo(first.date));
  }

  bool _hasTeam(Game game, String teamId) =>
      game.homeTeamId == teamId || game.visitorTeamId == teamId;

  bool _isBefore(Game game, DateTime date) {
    final gameDate = DateTime.tryParse(game.date);
    if (gameDate == null) return false;
    return gameDate.isBefore(DateTime(date.year, date.month, date.day));
  }

  int _seasonFor(DateTime date) => date.month >= 7 ? date.year : date.year - 1;

  void _ensureTeamId(String teamId) {
    if (teamId.trim().isEmpty) {
      throw const BasketballDataException(
        'This EuroLeague game is missing a team code for analysis.',
      );
    }
  }
}

class _CachedSeason {
  const _CachedSeason({this.games, this.inFlight, required this.expiresAt});

  final List<Game>? games;
  final Future<List<Game>>? inFlight;
  final DateTime expiresAt;
}
