import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../services/basketball_data_provider.dart';
import '../services/basketball_api.dart';
import 'ball_dont_lie_provider.dart';
import 'euroleague_provider.dart';

final apiProvider = Provider<BasketballApi>((ref) => BasketballApi());

final selectedLeagueProvider = StateProvider<String>((ref) => 'NBA');

final ballDontLieProvider = Provider<BasketballDataProvider>((ref) {
  return BallDontLieDataProvider(ref.watch(apiProvider));
});

final euroLeagueProvider = Provider<BasketballDataProvider>((ref) {
  return EuroLeagueDataProvider();
});

final basketballDataProvider = Provider<BasketballDataProvider>((ref) {
  final league = ref.watch(selectedLeagueProvider);
  return switch (league) {
    'NBA' => ref.watch(ballDontLieProvider),
    'EuroLeague' => ref.watch(euroLeagueProvider),
    _ => UnsupportedLeagueDataProvider(league),
  };
});

final gamesProvider = FutureProvider<List<Game>>((ref) {
  final league = ref.watch(selectedLeagueProvider);
  return ref.watch(basketballDataProvider).getGames(league: league);
});
