import '../models/game.dart';
import '../services/basketball_api.dart';
import '../services/basketball_data_provider.dart';

class BallDontLieDataProvider implements BasketballDataProvider {
  const BallDontLieDataProvider(this._api);

  final BasketballApi _api;

  @override
  String? get attribution => null;

  @override
  Future<List<Game>> getGames({String? league}) => _api.getGames();

  @override
  Future<List<Game>> getTeamGames(
    String teamId, {
    required DateTime beforeDate,
  }) {
    final id = int.tryParse(teamId);
    if (id == null || id <= 0) {
      throw const BasketballDataException(
        'This BallDontLie team ID is invalid.',
      );
    }
    return _api.getTeamGames(id, beforeDate: beforeDate);
  }

  @override
  Future<List<Game>> getHeadToHeadGames({
    required String homeTeamId,
    required String awayTeamId,
    required DateTime beforeDate,
  }) {
    final homeId = int.tryParse(homeTeamId);
    final awayId = int.tryParse(awayTeamId);
    if (homeId == null || homeId <= 0 || awayId == null || awayId <= 0) {
      throw const BasketballDataException(
        'This BallDontLie game is missing valid team IDs.',
      );
    }
    return _api.getHeadToHeadGames(
      homeTeamId: homeId,
      awayTeamId: awayId,
      beforeDate: beforeDate,
    );
  }
}
