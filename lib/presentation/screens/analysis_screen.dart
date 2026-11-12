import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/team_logos.dart';
import '../../data/models/game.dart';
import '../../data/models/game_analysis.dart';
import '../../data/providers/analysis_provider.dart';
import '../../data/providers/game_provider.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisProvider(game));
    final attribution = ref.watch(basketballDataProvider).attribution;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MATCH ANALYSIS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: analysisAsync.when(
              data: _buildAnalysisContent,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 40,
                        color: AppColors.liveRed,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load match analysis.\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(analysisProvider(game)),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (attribution != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Text(
                  attribution,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(GameAnalysis analysis) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MatchHeader(game: analysis.currentGame),
        const SizedBox(height: 20),
        _ProjectionCard(projection: analysis.projection),
        const SizedBox(height: 16),
        _FormCard(analysis: analysis),
        const SizedBox(height: 16),
        _HeadToHeadCard(analysis: analysis),
      ],
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(game.date);
    final displayDate = date == null ? game.date : DateFormat.yMMMd().format(date);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Text(
            displayDate,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MatchTeam(
                  name: game.homeTeamName,
                  teamId: game.homeTeamId,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      '${game.homeTeamScore} - ${game.visitorTeamScore}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      game.status.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _MatchTeam(
                  name: game.visitorTeamName,
                  teamId: game.visitorTeamId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchTeam extends StatelessWidget {
  const _MatchTeam({required this.name, required this.teamId});

  final String name;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TeamLogo(teamName: name, teamId: teamId),
        const SizedBox(height: 10),
        Text(
          _shortName(name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _shortName(String teamName) {
    final words = teamName.trim().split(RegExp(r'\s+'));
    return words.isEmpty ? teamName : words.last;
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.teamName, required this.teamId});

  final String teamName;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final logoUrl = TeamLogos.getLogoUrl(teamName);
    if (logoUrl == null) return _fallback();

    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: 68,
      height: 68,
      fit: BoxFit.contain,
      placeholder: (context, url) => _fallback(),
      errorWidget: (context, url, error) => _fallback(),
    );
  }

  Widget _fallback() {
    final initials = teamName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(3)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 34,
      backgroundColor: AppColors.surfaceLight,
      child: Text(
        initials.isEmpty ? teamId : initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.projection});

  final String projection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, color: AppColors.primary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FORM-BASED INDICATOR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  projection,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Simple recent-form heuristic; informational only.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.analysis});

  final GameAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT FORM  ·  LAST 5',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _FormRow(
            teamName: analysis.currentGame.homeTeamName,
            form: analysis.homeForm,
          ),
          const SizedBox(height: 14),
          _FormRow(
            teamName: analysis.currentGame.visitorTeamName,
            form: analysis.awayForm,
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.teamName, required this.form});

  final String teamName;
  final List<GameResult> form;

  @override
  Widget build(BuildContext context) {
    final words = teamName.trim().split(RegExp(r'\s+'));
    final label = words.isEmpty ? teamName : words.last;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (form.isEmpty)
          const Text(
            'No recent games',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )
        else
          for (final result in form)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _FormDot(result: result),
            ),
      ],
    );
  }
}

class _FormDot extends StatelessWidget {
  const _FormDot({required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final isWin = result == GameResult.win;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isWin ? AppColors.winGreen : AppColors.liveRed,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isWin ? 'W' : 'L',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _HeadToHeadCard extends StatelessWidget {
  const _HeadToHeadCard({required this.analysis});

  final GameAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final record = analysis.h2hRecord;
    final homeName = _shortName(analysis.currentGame.homeTeamName);
    final awayName = _shortName(analysis.currentGame.visitorTeamName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'HEAD TO HEAD  ·  LAST 5 SEASONS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeadToHeadRecord(
                  teamName: homeName,
                  wins: record['home'] ?? 0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: _HeadToHeadRecord(
                  teamName: awayName,
                  wins: record['away'] ?? 0,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (analysis.headToHeadGames.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'No completed matchups found in this period.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _shortName(String teamName) {
    final words = teamName.trim().split(RegExp(r'\s+'));
    return words.isEmpty ? teamName : words.last;
  }
}

class _HeadToHeadRecord extends StatelessWidget {
  const _HeadToHeadRecord({
    required this.teamName,
    required this.wins,
    this.alignEnd = false,
  });

  final String teamName;
  final int wins;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$wins WINS',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
