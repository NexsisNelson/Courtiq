import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LeagueFilter extends StatelessWidget {
  const LeagueFilter({
    super.key,
    required this.selectedLeague,
    required this.onSelected,
  });

  static const leagues = ['NBA', 'EuroLeague', 'ACB', 'NBL', 'Favorites'];

  final String selectedLeague;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final league in leagues)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(league),
                selected: league == selectedLeague,
                onSelected: (_) => onSelected(league),
                selectedColor: AppColors.background,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: league == selectedLeague
                      ? AppColors.primary
                      : AppColors.surface,
                  width: 1.5,
                ),
                labelStyle: TextStyle(
                  color: league == selectedLeague
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}
