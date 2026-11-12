import '../models/game.dart';

abstract interface class BasketballDataProvider {
  String? get attribution;

  Future<List<Game>> getGames({String? league});

  Future<List<Game>> getTeamGames(
    String teamId, {
    required DateTime beforeDate,
  });

  Future<List<Game>> getHeadToHeadGames({
    required String homeTeamId,
    required String awayTeamId,
    required DateTime beforeDate,
  });
}

class BasketballDataException implements Exception {
  const BasketballDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UnsupportedLeagueDataProvider implements BasketballDataProvider {
  const UnsupportedLeagueDataProvider(this.league);

  final String league;

  BasketballDataException _notAvailable() {
    return BasketballDataException('$league data is not connected yet.');
  }

  @override
  String? get attribution => null;

  @override
  Future<List<Game>> getGames({String? league}) async {
    throw _notAvailable();
  }

  @override
  Future<List<Game>> getTeamGames(
    String teamId, {
    required DateTime beforeDate,
  }) async {
    throw _notAvailable();
  }

  @override
  Future<List<Game>> getHeadToHeadGames({
    required String homeTeamId,
    required String awayTeamId,
    required DateTime beforeDate,
  }) async {
    throw _notAvailable();
  }
}
