import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ──────────────────────────────────────────────
// Calendar Widget
// Used: Calendar screen (9.2.6)
// ──────────────────────────────────────────────
class AppCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final Color selectedColor;
  final Color dayColor;

  const AppCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.selectedColor = AppColors.oceanBlue,
    this.dayColor = AppColors.lightBlue,
  });

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;
    // Monday = 1, Sunday = 7 → convert to 0-indexed
    final startOffset = firstWeekday - 1;

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Column(
      children: [
        // Header: Month + Year + arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _previousMonth,
              child: const Icon(
                QasehIcons.arrowLeftCurved,
                color: AppColors.caribbeanGreen,
              ),
            ),
            Text(
              '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
              style: AppTypography.menuItem.copyWith(
                color: AppColors.caribbeanGreen,
              ),
            ),
            GestureDetector(
              onTap: _nextMonth,
              child: const Icon(
                QasehIcons.arrowRightCurved,
                color: AppColors.caribbeanGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays.map((day) {
            return SizedBox(
              width: 32,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: AppTypography.chartLabel.copyWith(
                  color: widget.dayColor,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Days grid
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(startOffset + daysInMonth, (index) {
            if (index < startOffset) {
              return const SizedBox(width: 36, height: 32);
            }
            final day = index - startOffset + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isSelected =
                date.day == _selectedDate.day &&
                date.month == _selectedDate.month &&
                date.year == _selectedDate.year;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = date);
                widget.onDateSelected?.call(date);
              },
              child: Container(
                width: 36,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? widget.selectedColor : null,
                  borderRadius: BorderRadius.circular(12.45),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTypography.chartLabel.copyWith(
                      color: isSelected
                          ? AppColors.honeydew
                          : AppColors.fenceGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
