import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class ProfileDateNavigator extends ConsumerWidget {
  final bool isDesktop;

  const ProfileDateNavigator({this.isDesktop = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilter = ref.watch(timeFilterProvider);

    final dateRangeText = ref.watch(dateRangeTextProvider);

    void navigateDate(bool forward) {
      final currentDate = ref.read(selectedProfileDateProvider);
      DateTime newDate;

      switch (timeFilter) {
        case TimeFilter.daily:
          newDate = currentDate.add(Duration(days: forward ? 1 : -1));
          break;
        case TimeFilter.week:
          newDate = currentDate.add(Duration(days: forward ? 7 : -7));
          break;
        case TimeFilter.month:
          final month = currentDate.month + (forward ? 1 : -1);
          newDate = DateTime(
            currentDate.year + (month > 12 ? 1 : (month < 1 ? -1 : 0)),
            month > 12 ? 1 : (month < 1 ? 12 : month),
            1,
          );
          break;
      }

      ref.read(selectedProfileDateProvider.notifier).state = newDate;
    }

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => navigateDate(false),
              color: Colors.white,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(switch (timeFilter) {
                  TimeFilter.daily => Icons.calendar_today,
                  TimeFilter.week => Icons.calendar_view_week,
                  TimeFilter.month => Icons.calendar_month,
                }, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  dateRangeText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => navigateDate(true),
              color: Colors.white,
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => navigateDate(false),
          visualDensity: VisualDensity.compact,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(switch (timeFilter) {
              TimeFilter.daily => Icons.calendar_today,
              TimeFilter.week => Icons.calendar_view_week,
              TimeFilter.month => Icons.calendar_month,
            }, size: 20),
            const SizedBox(width: 8),
            Text(
              dateRangeText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => navigateDate(true),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
