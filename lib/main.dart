import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/models/game.dart';
import 'data/providers/game_provider.dart';
import 'presentation/screens/analysis_screen.dart';
import 'presentation/widgets/date_picker.dart';
import 'presentation/widgets/game_card.dart';
import 'presentation/widgets/league_filter.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CourtIQApp(),
    ),
  );
}

class CourtIQApp extends StatelessWidget {
  const CourtIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CourtIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDate;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);
    final dataProvider = ref.watch(basketballDataProvider);
    final attribution = dataProvider.attribution;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search teams',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Row(
                children: [
                  Icon(Icons.sports_basketball, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'COURTIQ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search teams',
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.textPrimary,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: 'Refresh games',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(gamesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: gamesAsync.when(
              data: (games) => _buildGames(games, selectedLeague),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.liveRed),
                  ),
                ),
              ),
            ),
          ),
          if (attribution != null)
            _AttributionBanner(text: attribution),
        ],
      ),
    );
  }

  Widget _buildGames(List<Game> games, String selectedLeague) {
    final dateKeys = games.map(_dateKey).toSet().toList()
      ..sort((first, second) => second.compareTo(first));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Scores & Analysis',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DatePickerRow(
          dates: dateKeys,
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 8),
        LeagueFilter(
          selectedLeague: selectedLeague,
          onSelected: (league) {
            ref.read(selectedLeagueProvider.notifier).state = league;
            setState(() => _selectedDate = null);
          },
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildGamesList(games)),
      ],
    );
  }

  Widget _buildGamesList(List<Game> games) {
    final visibleGames = games.where((game) {
      final matchesDate = _selectedDate == null || _dateKey(game) == _selectedDate;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          game.homeTeamName.toLowerCase().contains(query) ||
          game.visitorTeamName.toLowerCase().contains(query);
      return matchesDate && matchesSearch;
    }).toList();

    if (visibleGames.isEmpty) {
      final message = games.isEmpty
          ? 'No games found.'
          : _searchQuery.isNotEmpty
          ? 'No teams match your search.'
          : 'No games on this date.';
      return Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: visibleGames.length,
      itemBuilder: (context, index) => GameCard(
        game: visibleGames[index],
        onAnalysisTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => AnalysisScreen(game: visibleGames[index]),
            ),
          );
        },
      ),
    );
  }

  String _dateKey(Game game) {
    final date = DateTime.tryParse(game.date);
    return date == null ? game.date : DateFormat('yyyy-MM-dd').format(date);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }
}

class _AttributionBanner extends StatelessWidget {
  const _AttributionBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
