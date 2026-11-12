import 'package:courtiq/data/models/game.dart';
import 'package:courtiq/data/models/game_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates recent form and head-to-head wins from completed games', () {
    const currentGame = Game(
      id: '99',
      date: '2025-01-30',
      homeTeamScore: 0,
      visitorTeamScore: 0,
      homeTeamName: 'Home Team',
      visitorTeamName: 'Away Team',
      homeTeamId: '1',
      visitorTeamId: '2',
      status: 'Scheduled',
    );
    const homeWin = Game(
      id: '1',
      date: '2025-01-20',
      homeTeamScore: 110,
      visitorTeamScore: 100,
      homeTeamName: 'Home Team',
      visitorTeamName: 'Away Team',
      homeTeamId: '1',
      visitorTeamId: '2',
      status: 'Final',
    );
    const awayWin = Game(
      id: '2',
      date: '2025-01-15',
      homeTeamScore: 104,
      visitorTeamScore: 108,
      homeTeamName: 'Away Team',
      visitorTeamName: 'Home Team',
      homeTeamId: '2',
      visitorTeamId: '1',
      status: 'Final',
    );
    const unfinishedGame = Game(
      id: '3',
      date: '2025-01-10',
      homeTeamScore: 10,
      visitorTeamScore: 8,
      homeTeamName: 'Home Team',
      visitorTeamName: 'Away Team',
      homeTeamId: '1',
      visitorTeamId: '2',
      status: 'Q1 02:00',
    );

    const analysis = GameAnalysis(
      currentGame: currentGame,
      homeTeamRecentGames: [homeWin, awayWin, unfinishedGame],
      awayTeamRecentGames: [homeWin, awayWin, unfinishedGame],
      headToHeadGames: [homeWin, awayWin, unfinishedGame],
    );

    expect(analysis.homeForm, [GameResult.win, GameResult.win]);
    expect(analysis.awayForm, [GameResult.loss, GameResult.loss]);
    expect(analysis.h2hRecord, {'home': 2, 'away': 0});
    expect(analysis.projection, 'Home Team favored');
  });

  test('reports insufficient form when either team has no completed games', () {
    const analysis = GameAnalysis(
      currentGame: Game(
        id: '1',
        date: '2025-01-30',
        homeTeamScore: 0,
        visitorTeamScore: 0,
        homeTeamName: 'Home Team',
        visitorTeamName: 'Away Team',
        homeTeamId: '1',
        visitorTeamId: '2',
        status: 'Scheduled',
      ),
      homeTeamRecentGames: [],
      awayTeamRecentGames: [],
      headToHeadGames: [],
    );

    expect(analysis.projection, 'Insufficient recent form');
    expect(analysis.h2hRecord, {'home': 0, 'away': 0});
  });
}
