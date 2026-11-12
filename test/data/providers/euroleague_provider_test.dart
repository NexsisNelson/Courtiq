import 'package:dio/dio.dart';
import 'package:courtiq/data/providers/euroleague_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses EuroLeague XML results into normalized games', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: '''
<results>
  <game>
    <date>Oct 17, 2025</date>
    <gamecode>E2025_47</gamecode>
    <hometeam>KOSNER BASKONIA VITORIA-GASTEIZ</hometeam>
    <homecode>BAS</homecode>
    <homescore>79</homescore>
    <awayteam>PARTIZAN MOZZART BET BELGRADE</awayteam>
    <awaycode>PAR</awaycode>
    <awayscore>91</awayscore>
    <played>true</played>
  </game>
  <game>
    <date>Nov 4, 2025</date>
    <gamecode>E2025_99</gamecode>
    <hometeam>FC BARCELONA</hometeam>
    <homecode>BAR</homecode>
    <homescore></homescore>
    <awayteam>REAL MADRID</awayteam>
    <awaycode>MAD</awaycode>
    <awayscore></awayscore>
    <played>false</played>
  </game>
</results>
''',
              ),
            );
          },
        ),
      );
    final provider = EuroLeagueDataProvider(
      dio: dio,
      clock: () => DateTime(2025, 11, 12),
    );

    final games = await provider.getGames(league: 'EuroLeague');

    expect(games, hasLength(2));
    expect(games.first.id, 'E2025_99');
    expect(games.first.date, '2025-11-04');
    expect(games.first.status, 'Scheduled');
    expect(games.first.homeTeamId, 'BAR');
    expect(games.last.homeTeamScore, 79);
    expect(games.last.visitorTeamScore, 91);
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['seasoncode'], 'E2025');
    expect(provider.attribution, 'Data powered by EuroLeague');
  });
}
