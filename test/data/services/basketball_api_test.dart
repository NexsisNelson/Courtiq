import 'package:dio/dio.dart';
import 'package:courtiq/data/services/basketball_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports missing API key before making a request', () async {
    final api = BasketballApi(apiKey: '');

    await expectLater(
      api.getGames(),
      throwsA(
        isA<BasketballApiException>().having(
          (error) => error.message,
          'message',
          contains('Missing BallDontLie API key'),
        ),
      ),
    );
  });

  test('fetches and caches a team history using the game date', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': [
                    _gameJson(1, '2025-01-28', 1, 3, 110, 100),
                    _gameJson(2, '2025-01-25', 1, 4, 105, 99),
                    _gameJson(3, '2025-01-22', 5, 1, 90, 101),
                    _gameJson(4, '2025-01-19', 1, 6, 112, 108),
                    _gameJson(5, '2025-01-16', 7, 1, 95, 98),
                  ],
                },
              ),
            );
          },
        ),
      );
    final api = BasketballApi(dio: dio, apiKey: 'test-key');

    final first = await api.getTeamGames(
      1,
      beforeDate: DateTime(2025, 1, 30),
    );
    final second = await api.getTeamGames(
      1,
      beforeDate: DateTime(2025, 1, 30),
    );

    expect(first.map((game) => game.id), ['1', '2', '3', '4', '5']);
    expect(second, hasLength(5));
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['team_ids[]'], [1]);
    expect(requests.single.queryParameters['seasons[]'], [2024]);
    expect(requests.single.queryParameters['end_date'], '2025-01-29');
  });

  test('head-to-head lookup keeps only completed matchups of both teams',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': [
                    _gameJson(1, '2025-01-20', 1, 2, 110, 100),
                    _gameJson(2, '2025-01-18', 1, 3, 105, 99),
                    _gameJson(
                      3,
                      '2025-01-15',
                      2,
                      1,
                      104,
                      108,
                      status: 'Final',
                    ),
                    _gameJson(
                      4,
                      '2025-01-10',
                      1,
                      2,
                      80,
                      75,
                      status: 'Q4 00:30',
                    ),
                  ],
                },
              ),
            );
          },
        ),
      );
    final api = BasketballApi(dio: dio, apiKey: 'test-key');

    final games = await api.getHeadToHeadGames(
      homeTeamId: 1,
      awayTeamId: 2,
      beforeDate: DateTime(2025, 1, 30),
    );

    expect(games.map((game) => game.id), ['1', '3']);
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['team_ids[]'], [1, 2]);
    expect(requests.single.queryParameters['per_page'], 100);
  });
}

Map<String, dynamic> _gameJson(
  int id,
  String date,
  int homeTeamId,
  int visitorTeamId,
  int homeScore,
  int visitorScore, {
  String status = 'Final',
}) {
  return {
    'id': id,
    'date': date,
    'home_team_score': homeScore,
    'visitor_team_score': visitorScore,
    'home_team': {'id': homeTeamId, 'full_name': 'Team $homeTeamId'},
    'visitor_team': {
      'id': visitorTeamId,
      'full_name': 'Team $visitorTeamId',
    },
    'status': status,
  };
}
