class Game {
  const Game({
    required this.id,
    required this.date,
    required this.homeTeamScore,
    required this.visitorTeamScore,
    required this.homeTeamName,
    required this.visitorTeamName,
    required this.homeTeamId,
    required this.visitorTeamId,
    required this.status,
  });

  final String id;
  final String date;
  final int homeTeamScore;
  final int visitorTeamScore;
  final String homeTeamName;
  final String visitorTeamName;
  final String homeTeamId;
  final String visitorTeamId;
  final String status;

  bool get isFinal => status.toLowerCase().contains('final');

  factory Game.fromJson(Map<String, dynamic> json) {
    final homeTeam = json['home_team'];
    final visitorTeam = json['visitor_team'];

    return Game(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      homeTeamScore: _asInt(json['home_team_score']),
      visitorTeamScore: _asInt(json['visitor_team_score']),
      homeTeamName: _teamName(homeTeam),
      visitorTeamName: _teamName(visitorTeam),
      homeTeamId: _teamId(homeTeam),
      visitorTeamId: _teamId(visitorTeam),
      status: json['status']?.toString() ?? 'Scheduled',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _teamName(dynamic team) {
    if (team is Map<String, dynamic>) {
      return team['full_name']?.toString() ?? 'TBD';
    }
    return 'TBD';
  }

  static String _teamId(dynamic team) {
    if (team is Map<String, dynamic>) {
      return team['id']?.toString() ?? '';
    }
    return '';
  }
}
