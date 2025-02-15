import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../providers/profile_provider.dart';

class ChartTypeToggle extends ConsumerWidget {
  final bool isDesktop;
  final Function(ChartType) onChanged;

  const ChartTypeToggle({
    super.key,
    this.isDesktop = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(chartTypeProvider);
    final timeFilter = ref.watch(timeFilterProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          ChartType.values.map((type) {
            final isSelected = currentType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ChartTypeButton(
                  type: type,
                  isSelected: isSelected,
                  onTap: () {
                    if (timeFilter == TimeFilter.daily &&
                        type == ChartType.line) {
                      ref.read(timeFilterProvider.notifier).state =
                          TimeFilter.week;
                    }
                    onChanged(type);
                  },
                  isDesktop: isDesktop,
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _ChartTypeButton extends StatelessWidget {
  final ChartType type;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDesktop;

  const _ChartTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected
              ? Colors.white.withAlpha(25)
              : isDesktop
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == ChartType.circular
                    ? Ionicons.pie_chart
                    : Ionicons.stats_chart,
                color:
                    isSelected
                        ? Colors.white
                        : isDesktop
                        ? Colors.white70
                        : Theme.of(context).primaryColor,
                size: 18,
              ),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                Text(
                  type.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
