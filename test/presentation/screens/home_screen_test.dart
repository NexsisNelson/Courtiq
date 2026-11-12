import 'package:courtiq/data/models/game.dart';
import 'package:courtiq/data/models/game_analysis.dart';
import 'package:courtiq/data/providers/analysis_provider.dart';
import 'package:courtiq/data/providers/game_provider.dart';
import 'package:courtiq/data/services/basketball_data_provider.dart';
import 'package:courtiq/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('date picker filters games and UI explains unavailable features',
      (
    tester,
  ) async {
    final games = [
      const Game(
        id: '1',
        date: '2025-01-01',
        homeTeamScore: 108,
        visitorTeamScore: 102,
        homeTeamName: 'Boston Celtics',
        visitorTeamName: 'Miami Heat',
        homeTeamId: '2',
        visitorTeamId: '3',
        status: 'Final',
      ),
      const Game(
        id: '2',
        date: '2025-01-02',
        homeTeamScore: 97,
        visitorTeamScore: 99,
        homeTeamName: 'LA Lakers',
        visitorTeamName: 'Golden State Warriors',
        homeTeamId: '13',
        visitorTeamId: '9',
        status: 'Final',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ballDontLieProvider.overrideWith(
            (ref) => _FakeBasketballDataProvider(games),
          ),
          euroLeagueProvider.overrideWith(
            (ref) => _FakeBasketballDataProvider(
              [
                const Game(
                  id: 'E2025_47',
                  date: '2025-01-03',
                  homeTeamScore: 79,
                  visitorTeamScore: 91,
                  homeTeamName: 'Baskonia',
                  visitorTeamName: 'Partizan',
                  homeTeamId: 'BAS',
                  visitorTeamId: 'PAR',
                  status: 'Final',
                ),
              ],
              attribution: 'Data powered by EuroLeague',
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Celtics'), findsOneWidget);
    expect(find.text('Lakers'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('game-date-2025-01-01')));
    await tester.pumpAndSettle();

    expect(find.text('Celtics'), findsOneWidget);
    expect(find.text('Lakers'), findsNothing);

    await tester.tap(find.text('EuroLeague'));
    await tester.pumpAndSettle();
    expect(find.text('Partizan'), findsOneWidget);
    expect(find.text('Data powered by EuroLeague'), findsOneWidget);
  });

  testWidgets('analysis action opens the analysis screen', (tester) async {
    const game = Game(
      id: '1',
      date: '2025-01-30',
      homeTeamScore: 108,
      visitorTeamScore: 102,
      homeTeamName: 'Boston Celtics',
      visitorTeamName: 'Miami Heat',
      homeTeamId: '2',
      visitorTeamId: '3',
      status: 'Final',
    );
    const analysis = GameAnalysis(
      currentGame: game,
      homeTeamRecentGames: [],
      awayTeamRecentGames: [],
      headToHeadGames: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ballDontLieProvider.overrideWith(
            (ref) => _FakeBasketballDataProvider([game]),
          ),
          analysisProvider(game).overrideWith((ref) async => analysis),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final analysisButton = find.text('VIEW MATCH ANALYSIS');
    await tester.ensureVisible(analysisButton);
    await tester.tap(analysisButton);
    await tester.pumpAndSettle();

    expect(find.text('MATCH ANALYSIS'), findsOneWidget);
    expect(find.text('Insufficient recent form'), findsOneWidget);
  });
}

class _FakeBasketballDataProvider implements BasketballDataProvider {
  _FakeBasketballDataProvider(
    this.games, {
    this.attribution,
  });

  final List<Game> games;

  @override
  final String? attribution;

  @override
  Future<List<Game>> getGames({String? league}) async => games;

  @override
  Future<List<Game>> getTeamGames(
    String teamId, {
    required DateTime beforeDate,
  }) async =>
      [];

  @override
  Future<List<Game>> getHeadToHeadGames({
    required String homeTeamId,
    required String awayTeamId,
    required DateTime beforeDate,
  }) async =>
      [];
}
