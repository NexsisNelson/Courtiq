import 'package:dio/dio.dart';

import '../models/game.dart';
import 'basketball_data_provider.dart';

class BasketballApiException extends BasketballDataException {
  const BasketballApiException(super.message);
}

class BasketballApi {
  BasketballApi({
    Dio? dio,
    String? apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey =
            apiKey ?? const String.fromEnvironment('BALLDONTLIE_API_KEY') {
    if (_apiKey.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    }
    _dio.options.baseUrl = 'https://api.balldontlie.io/v1';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  static const _historyCacheDuration = Duration(minutes: 10);

  final Dio _dio;
  final String _apiKey;
  final Map<String, _CachedGames> _historyCache = {};

  Future<List<Game>> getGames() async {
    _ensureApiKey();
    return _requestGames();
  }

  Future<List<Game>> getTeamGames(
    int teamId, {
    required DateTime beforeDate,
  }) async {
    _ensureTeamId(teamId);
    final endDate = _dayBefore(beforeDate);
    final season = _seasonFor(beforeDate);

    final currentSeasonGames = await _cachedGames(
      'team:$teamId:$season:$endDate',
      {
        'team_ids[]': [teamId],
        'seasons[]': [season],
        'end_date': endDate,
        'per_page': 100,
      },
    );
    final recentGames = _completedGamesBefore(currentSeasonGames, beforeDate);
    if (recentGames.length >= 5) {
      return recentGames.take(5).toList(growable: false);
    }

    final previousSeasonGames = await _cachedGames(
      'team:$teamId:${season - 1}:$endDate',
      {
        'team_ids[]': [teamId],
        'seasons[]': [season - 1],
        'end_date': endDate,
        'per_page': 100,
      },
    );
    return _sortNewestFirst([
      ...recentGames,
      ..._completedGamesBefore(previousSeasonGames, beforeDate),
    ]).take(5).toList(growable: false);
  }

  Future<List<Game>> getHeadToHeadGames({
    required int homeTeamId,
    required int awayTeamId,
    required DateTime beforeDate,
  }) async {
    _ensureTeamId(homeTeamId);
    _ensureTeamId(awayTeamId);
    if (homeTeamId == awayTeamId) {
      throw const BasketballApiException(
        'A head-to-head lookup requires two different teams.',
      );
    }

    final endDate = _dayBefore(beforeDate);
    final season = _seasonFor(beforeDate);
    final seasons = List<int>.generate(5, (index) => season - index);
    final pair = [homeTeamId, awayTeamId]..sort();
    final games = await _cachedGames(
      'head-to-head:${pair[0]}:${pair[1]}:$endDate',
      {
        'team_ids[]': pair,
        'seasons[]': seasons,
        'end_date': endDate,
        'per_page': 100,
      },
    );

    return _sortNewestFirst(
      games.where(
        (game) =>
            game.isFinal &&
            _isBefore(game, beforeDate) &&
            ((game.homeTeamId == '$homeTeamId' &&
                    game.visitorTeamId == '$awayTeamId') ||
                (game.homeTeamId == '$awayTeamId' &&
                    game.visitorTeamId == '$homeTeamId')),
      ),
    );
  }

  Future<List<Game>> _cachedGames(
    String key,
    Map<String, dynamic> queryParameters,
  ) async {
    final cached = _historyCache[key];
    final now = DateTime.now();
    if (cached != null && cached.expiresAt.isAfter(now)) {
      if (cached.games != null) return cached.games!;
      if (cached.inFlight != null) return cached.inFlight!;
    }

    final request = _requestGames(queryParameters);
    final pending = _CachedGames(
      inFlight: request,
      expiresAt: now.add(_historyCacheDuration),
    );
    _historyCache[key] = pending;

    try {
      final games = await request;
      _historyCache[key] = _CachedGames(
        games: List.unmodifiable(games),
        expiresAt: DateTime.now().add(_historyCacheDuration),
      );
      return games;
    } catch (_) {
      if (identical(_historyCache[key], pending)) {
        _historyCache.remove(key);
      }
      rethrow;
    }
  }

  Future<List<Game>> _requestGames([
    Map<String, dynamic> queryParameters = const {},
  ]) async {
    _ensureApiKey();

    try {
      final response = await _dio.get<dynamic>(
        '/games',
        queryParameters: queryParameters,
      );
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> ||
          responseData['data'] is! List) {
        throw const BasketballApiException(
          'Unexpected response from the BallDontLie API.',
        );
      }

      return (responseData['data'] as List).map((game) {
        if (game is! Map<String, dynamic>) {
          throw const BasketballApiException(
            'Unexpected game data from the BallDontLie API.',
          );
        }
        return Game.fromJson(game);
      }).toList(growable: false);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        throw const BasketballApiException(
          'BallDontLie rate limit exceeded. Please wait before retrying.',
        );
      }
      if (statusCode == 401) {
        throw const BasketballApiException(
          'BallDontLie rejected the API key. Check your key and try again.',
        );
      }
      throw BasketballApiException(
        'Could not load games: ${error.message ?? 'network request failed'}.',
      );
    }
  }

  List<Game> _completedGamesBefore(List<Game> games, DateTime beforeDate) {
    return _sortNewestFirst(
      games.where((game) => game.isFinal && _isBefore(game, beforeDate)),
    );
  }

  List<Game> _sortNewestFirst(Iterable<Game> games) {
    return games.toList()
      ..sort((first, second) => second.date.compareTo(first.date));
  }

  bool _isBefore(Game game, DateTime date) {
    final gameDate = DateTime.tryParse(game.date);
    if (gameDate == null) return false;
    final cutoff = DateTime(date.year, date.month, date.day);
    return gameDate.isBefore(cutoff);
  }

  int _seasonFor(DateTime date) => date.month >= 10 ? date.year : date.year - 1;

  String _dayBefore(DateTime date) {
    final dayBefore = DateTime(date.year, date.month, date.day - 1);
    final month = dayBefore.month.toString().padLeft(2, '0');
    final day = dayBefore.day.toString().padLeft(2, '0');
    return '${dayBefore.year}-$month-$day';
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw const BasketballApiException(
        'Missing BallDontLie API key. Run with '
        '--dart-define=BALLDONTLIE_API_KEY=your_key.',
      );
    }
  }

  void _ensureTeamId(int teamId) {
    _ensureApiKey();
    if (teamId <= 0) {
      throw const BasketballApiException(
        'This game is missing a valid team ID for analysis.',
      );
    }
  }
}

class _CachedGames {
  const _CachedGames({this.games, this.inFlight, required this.expiresAt});

  final List<Game>? games;
  final Future<List<Game>>? inFlight;
  final DateTime expiresAt;
}
