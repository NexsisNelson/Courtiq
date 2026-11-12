import 'game.dart';

enum GameResult { win, loss }

class GameAnalysis {
  const GameAnalysis({
    required this.currentGame,
    required this.homeTeamRecentGames,
    required this.awayTeamRecentGames,
    required this.headToHeadGames,
  });

  final Game currentGame;
  final List<Game> homeTeamRecentGames;
  final List<Game> awayTeamRecentGames;
  final List<Game> headToHeadGames;

  List<GameResult> get homeForm =>
      _calculateForm(homeTeamRecentGames, currentGame.homeTeamId);

  List<GameResult> get awayForm =>
      _calculateForm(awayTeamRecentGames, currentGame.visitorTeamId);

  Map<String, int> get h2hRecord {
    var homeWins = 0;
    var awayWins = 0;

    for (final game in headToHeadGames) {
      if (!game.isFinal || game.homeTeamScore == game.visitorTeamScore) {
        continue;
      }

      final winnerId = game.homeTeamScore > game.visitorTeamScore
          ? game.homeTeamId
          : game.visitorTeamId;
      if (winnerId == currentGame.homeTeamId) {
        homeWins++;
      } else if (winnerId == currentGame.visitorTeamId) {
        awayWins++;
      }
    }

    return {'home': homeWins, 'away': awayWins};
  }

  String get projection {
    if (homeForm.isEmpty || awayForm.isEmpty) {
      return 'Insufficient recent form';
    }

    final homeWins = homeForm.where((result) => result == GameResult.win).length;
    final awayWins = awayForm.where((result) => result == GameResult.win).length;
    if (homeWins + 1 > awayWins) {
      return '${currentGame.homeTeamName} favored';
    }
    if (awayWins > homeWins + 1) {
      return '${currentGame.visitorTeamName} favored';
    }
    return 'Even matchup';
  }

  List<GameResult> _calculateForm(List<Game> games, String teamId) {
    return games
        .where(
          (game) =>
              game.isFinal &&
              (game.homeTeamId == teamId || game.visitorTeamId == teamId),
        )
        .take(5)
        .map((game) {
          final isHome = game.homeTeamId == teamId;
          final teamScore = isHome
              ? game.homeTeamScore
              : game.visitorTeamScore;
          final opponentScore = isHome
              ? game.visitorTeamScore
              : game.homeTeamScore;
          return teamScore > opponentScore
              ? GameResult.win
              : GameResult.loss;
        })
        .toList(growable: false);
  }
}
