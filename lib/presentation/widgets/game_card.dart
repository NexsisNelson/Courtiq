import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/team_logos.dart';
import '../../data/models/game.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.onAnalysisTap,
  });

  final Game game;
  final VoidCallback onAnalysisTap;

  @override
  Widget build(BuildContext context) {
    final isFinal = game.status.toLowerCase().contains('final');
    final isLive = !isFinal &&
        RegExp(
          r'\b(Q[1-4]|QTR|OT|HALF)\b|\d{1,2}:\d{2}',
          caseSensitive: false,
        ).hasMatch(game.status);
    final parsedDate = DateTime.tryParse(game.date);
    final displayDate = parsedDate == null
        ? game.date
        : DateFormat.yMMMd().format(parsedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLive
              ? AppColors.liveRed.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isLive)
                const _LiveBadge()
              else
                Text(
                  game.status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TeamSide(
                  teamName: game.homeTeamName,
                  isHome: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${game.homeTeamScore} - ${game.visitorTeamScore}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: _TeamSide(
                  teamName: game.visitorTeamName,
                  isHome: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onAnalysisTap,
              icon: const Icon(Icons.analytics_outlined, size: 17),
              label: const Text('VIEW MATCH ANALYSIS'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.teamName, required this.isHome});

  final String teamName;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final logo = _TeamLogo(teamName: teamName);
    final name = Expanded(
      child: Text(
        _shortName(teamName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isHome ? TextAlign.left : TextAlign.right,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Row(
      children: isHome
          ? [logo, const SizedBox(width: 8), name]
          : [name, const SizedBox(width: 8), logo],
    );
  }

  String _shortName(String teamName) {
    final words = teamName.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return teamName;
    return words.last;
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final logoUrl = TeamLogos.getLogoUrl(teamName);
    if (logoUrl == null) return _fallbackLogo();

    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: 42,
      height: 42,
      fit: BoxFit.contain,
      placeholder: (context, url) => _fallbackLogo(),
      errorWidget: (context, url, error) => _fallbackLogo(),
    );
  }

  Widget _fallbackLogo() {
    final initials = teamName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(3)
        .map((word) => word[0])
        .join()
        .toUpperCase();

    return CircleAvatar(
      radius: 21,
      backgroundColor: AppColors.surfaceLight,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.circle, size: 7, color: AppColors.liveRed),
        SizedBox(width: 6),
        Text(
          'LIVE',
          style: TextStyle(
            color: AppColors.liveRed,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}
