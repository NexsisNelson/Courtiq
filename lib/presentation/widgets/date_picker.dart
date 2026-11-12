import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DatePickerRow extends StatelessWidget {
  const DatePickerRow({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<String> dates;
  final String? selectedDate;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _DateChip(
            key: const ValueKey('all-game-dates'),
            day: 'ALL',
            date: 'GAMES',
            selected: selectedDate == null,
            onTap: () => onSelected(null),
          ),
          for (final dateKey in dates)
            _DateChip(
              key: ValueKey('game-date-$dateKey'),
              day: _dayName(dateKey),
              date: _dayNumber(dateKey),
              selected: dateKey == selectedDate,
              onTap: () => onSelected(dateKey),
            ),
        ],
      ),
    );
  }

  String _dayName(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return '—';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _dayNumber(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    return date == null ? '—' : '${date.day}';
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    super.key,
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final String day;
  final String date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(day, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 3),
              Text(date, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
        ),
        labelStyle: TextStyle(
          color: selected ? AppColors.background : AppColors.textPrimary,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
