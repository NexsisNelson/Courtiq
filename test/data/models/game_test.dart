import 'package:courtiq/data/models/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Game.fromJson', () {
    test('maps game fields and nested team names', () {
      final game = Game.fromJson({
        'id': 42,
        'date': '2025-01-15',
        'home_team_score': 101,
        'visitor_team_score': 98,
        'home_team': {'id': 10, 'full_name': 'Home Team'},
        'visitor_team': {'id': 20, 'full_name': 'Visitor Team'},
        'status': 'Final',
      });

      expect(game.id, '42');
      expect(game.date, '2025-01-15');
      expect(game.homeTeamScore, 101);
      expect(game.visitorTeamScore, 98);
      expect(game.homeTeamName, 'Home Team');
      expect(game.visitorTeamName, 'Visitor Team');
      expect(game.homeTeamId, '10');
      expect(game.visitorTeamId, '20');
      expect(game.status, 'Final');
    });

    test('uses safe defaults for missing or unexpected fields', () {
      final game = Game.fromJson({
        'id': 'not-an-id',
        'home_team_score': null,
        'home_team': null,
      });

      expect(game.id, 'not-an-id');
      expect(game.date, '');
      expect(game.homeTeamScore, 0);
      expect(game.visitorTeamScore, 0);
      expect(game.homeTeamName, 'TBD');
      expect(game.visitorTeamName, 'TBD');
      expect(game.homeTeamId, '');
      expect(game.visitorTeamId, '');
      expect(game.status, 'Scheduled');
    });
  });
}
