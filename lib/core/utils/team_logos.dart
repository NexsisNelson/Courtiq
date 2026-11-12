class TeamLogos {
  static const Map<String, String> _teamAbbreviations = {
    'Atlanta Hawks': 'atl',
    'Boston Celtics': 'bos',
    'Brooklyn Nets': 'bkn',
    'Charlotte Hornets': 'cha',
    'Chicago Bulls': 'chi',
    'Cleveland Cavaliers': 'cle',
    'Dallas Mavericks': 'dal',
    'Denver Nuggets': 'den',
    'Detroit Pistons': 'det',
    'Golden State Warriors': 'gs',
    'Houston Rockets': 'hou',
    'Indiana Pacers': 'ind',
    'LA Clippers': 'lac',
    'Los Angeles Clippers': 'lac',
    'Los Angeles Lakers': 'lal',
    'Memphis Grizzlies': 'mem',
    'Miami Heat': 'mia',
    'Milwaukee Bucks': 'mil',
    'Minnesota Timberwolves': 'min',
    'New Orleans Pelicans': 'no',
    'New York Knicks': 'ny',
    'Oklahoma City Thunder': 'okc',
    'Orlando Magic': 'orl',
    'Philadelphia 76ers': 'phi',
    'Phoenix Suns': 'phx',
    'Portland Trail Blazers': 'por',
    'Sacramento Kings': 'sac',
    'San Antonio Spurs': 'sa',
    'Toronto Raptors': 'tor',
    'Utah Jazz': 'utah',
    'Washington Wizards': 'wsh',
  };

  static String? getLogoUrl(String teamName) {
    final abbreviation = _teamAbbreviations[teamName];
    if (abbreviation == null) return null;
    return 'https://a.espncdn.com/i/teamlogos/nba/500/$abbreviation.png';
  }
}
