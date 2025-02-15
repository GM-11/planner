import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:planner/features/calendar/presentation/widgets/calender_shimmer.dart';
import '../providers/calendar_provider.dart';
import 'views/daily_view.dart';
import 'views/weekly_view.dart';
import 'views/monthly_view.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        return isDesktop ? const _DesktopLayout() : const _MobileLayout();
      },
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(calendarViewTypeProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildDateHeader(ref),
                const SizedBox(height: 16),
                _buildViewTypeSelector(context, viewType),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (_) => _buildCalendarView(viewType),
              loading: () => CalendarShimmer(viewType: viewType),
              error:
                  (error, stack) =>
                      Center(child: Text('Error: ${error.toString()}')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(calendarViewTypeProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 400,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  DateFormat(
                    'MMMM yyyy',
                  ).format(ref.watch(calendarSelectedDateProvider)),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                const Text(
                  'View Type',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDesktopViewTypeSelector(context, viewType),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: tasksAsync.when(
              data: (_) => _buildCalendarView(viewType),
              loading: () => CalendarShimmer(viewType: viewType),
              error:
                  (error, stack) =>
                      Center(child: Text('Error: ${error.toString()}')),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDateHeader(WidgetRef ref) {
  return Row(
    children: [
      Text(
        DateFormat('MMMM yyyy').format(ref.watch(calendarSelectedDateProvider)),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

Widget _buildViewTypeSelector(BuildContext context, CalendarViewType viewType) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (final type in CalendarViewType.values) ...[
        if (CalendarViewType.values.indexOf(type) > 0) const SizedBox(width: 8),
        _ViewTypeButton(
          type: type,
          isSelected: viewType == type,
          key: ValueKey(type),
        ),
      ],
    ],
  );
}

Widget _buildDesktopViewTypeSelector(
  BuildContext context,
  CalendarViewType viewType,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (final type in CalendarViewType.values) ...[
        if (CalendarViewType.values.indexOf(type) > 0)
          const SizedBox(height: 8),
        _ViewTypeButton(
          type: type,
          isSelected: viewType == type,
          isDesktop: true,
          key: ValueKey(type),
        ),
      ],
    ],
  );
}

Widget _buildCalendarView(CalendarViewType viewType) {
  return switch (viewType) {
    CalendarViewType.daily => const DailyView(),
    CalendarViewType.weekly => const WeeklyView(),
    CalendarViewType.monthly => const MonthlyView(),
  };
}

class _ViewTypeButton extends ConsumerWidget {
  final CalendarViewType type;
  final bool isSelected;
  final bool isDesktop;

  const _ViewTypeButton({
    required this.type,
    required this.isSelected,
    this.isDesktop = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color:
          isSelected
              ? Colors.white.withAlpha(25)
              : (isDesktop
                  ? Colors.transparent
                  : Theme.of(context).primaryColor),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          ref.read(calendarViewTypeProvider.notifier).state = type;
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            switch (type) {
              CalendarViewType.daily => 'Daily',
              CalendarViewType.weekly => 'Weekly',
              CalendarViewType.monthly => 'Monthly',
            },
            textAlign: isDesktop ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color:
                  isDesktop
                      ? Colors.white70
                      : Colors.white.withAlpha(isSelected ? 255 : 178),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
