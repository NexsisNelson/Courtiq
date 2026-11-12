import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../models/game_analysis.dart';
import '../services/basketball_data_provider.dart';
import 'game_provider.dart';

final analysisProvider = FutureProvider.family<GameAnalysis, Game>((
  ref,
  game,
) async {
  if (game.homeTeamId.isEmpty || game.visitorTeamId.isEmpty) {
    throw const BasketballDataException(
      'This game is missing team IDs, so analysis cannot be loaded.',
    );
  }
  if (game.homeTeamId == game.visitorTeamId) {
    throw const BasketballDataException(
      'This game has invalid team IDs, so analysis cannot be loaded.',
    );
  }

  final beforeDate = DateTime.tryParse(game.date);
  if (beforeDate == null) {
    throw const BasketballDataException(
      'This game has an invalid date, so historical analysis cannot be loaded.',
    );
  }

  final provider = ref.watch(basketballDataProvider);
  final histories = await Future.wait<List<Game>>([
    provider.getTeamGames(game.homeTeamId, beforeDate: beforeDate),
    provider.getTeamGames(game.visitorTeamId, beforeDate: beforeDate),
    provider.getHeadToHeadGames(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.visitorTeamId,
      beforeDate: beforeDate,
    ),
  ]);

  return GameAnalysis(
    currentGame: game,
    homeTeamRecentGames: histories[0],
    awayTeamRecentGames: histories[1],
    headToHeadGames: histories[2],
  );
});
