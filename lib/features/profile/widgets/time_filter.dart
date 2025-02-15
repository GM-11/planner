import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/features/profile/providers/profile_provider.dart';

class TimeFilterWidget extends ConsumerWidget {
  final bool isDesktop;
  final Function(TimeFilter) onChanged;

  const TimeFilterWidget({
    super.key,
    this.isDesktop = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(timeFilterProvider);
    final chartType = ref.watch(chartTypeProvider);
    final filters =
        chartType == ChartType.circular
            ? TimeFilter.values
            : [TimeFilter.week, TimeFilter.month];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          filters.map((filter) {
            final isSelected = currentFilter == filter;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _FilterButton(
                  label: filter.name,
                  isSelected: isSelected,
                  onTap: () => onChanged(filter),
                  isDesktop: isDesktop,
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDesktop;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected
              ? Theme.of(context).primaryColor
              : isDesktop
              ? Colors.white.withOpacity(0.1)
              : Theme.of(context).primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label.capitalize(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isSelected
                      ? Colors.white
                      : isDesktop
                      ? Colors.white70
                      : Theme.of(context).primaryColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
