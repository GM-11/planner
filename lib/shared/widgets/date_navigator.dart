import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

class DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChange;
  final bool isDark;

  const DateNavigator({
    super.key,
    required this.selectedDate,
    required this.onDateChange,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateTime.now().day == selectedDate.day &&
        DateTime.now().month == selectedDate.month &&
        DateTime.now().year == selectedDate.year;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavigatorButton(
            icon: Ionicons.chevron_back,
            onPressed:
                () => onDateChange(
                  selectedDate.subtract(const Duration(days: 1)),
                ),
            isDark: isDark,
          ),
          Column(
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE').format(selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          _NavigatorButton(
            icon: Ionicons.chevron_forward,
            onPressed:
                () => onDateChange(selectedDate.add(const Duration(days: 1))),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _NavigatorButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;

  const _NavigatorButton({
    required this.icon,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(13),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : Colors.black),
        onPressed: onPressed,
      ),
    );
  }
}
