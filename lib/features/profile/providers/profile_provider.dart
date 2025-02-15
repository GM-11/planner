import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:planner/features/tasks/providers/tasks_provider.dart';
import '../../../shared/models/task.dart';

enum TimeFilter { daily, week, month }

enum ChartType { circular, line }

final timeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.daily);
final chartTypeProvider = StateProvider<ChartType>((ref) => ChartType.circular);

final dateRangeTextProvider = Provider<String>((ref) {
  final timeFilter = ref.watch(timeFilterProvider);
  final selectedDate = ref.watch(selectedProfileDateProvider);

  switch (timeFilter) {
    case TimeFilter.daily:
      return DateFormat('MMMM d, yyyy').format(selectedDate);

    case TimeFilter.week:
      final startOfWeek = selectedDate.subtract(
        Duration(days: selectedDate.weekday % 7),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';

    case TimeFilter.month:
      return DateFormat('MMMM yyyy').format(selectedDate);
  }
});

final performanceMetricsProvider = Provider<PerformanceMetrics>((ref) {
  final timeFilter = ref.watch(timeFilterProvider);
  final tasksAsync = ref.watch(tasksStateProvider);
  final selectedDate = ref.watch(selectedProfileDateProvider);

  return tasksAsync.when(
    data: (tasks) {
      final filteredTasks = switch (timeFilter) {
        TimeFilter.daily => _getDailyTasks(tasks, selectedDate),
        TimeFilter.week => _getWeeklyTasks(tasks, selectedDate),
        TimeFilter.month => _getMonthlyTasks(tasks, selectedDate),
      };

      final dateRange = switch (timeFilter) {
        TimeFilter.daily => [selectedDate],
        TimeFilter.week => _getWeekDates(selectedDate),
        TimeFilter.month => _getMonthDates(selectedDate),
      };

      return _calculateMetrics(filteredTasks, dateRange);
    },
    loading: () => PerformanceMetrics.empty(),
    error: (_, __) => PerformanceMetrics.empty(),
  );
});

final selectedProfileDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// Helper Functions
List<DateTime> _getWeekDates(DateTime date) {
  // Start from Sunday
  final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
  return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
}

List<DateTime> _getMonthDates(DateTime date) {
  final startOfMonth = DateTime(date.year, date.month, 1);
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;

  return List.generate(
    daysInMonth,
    (index) => startOfMonth.add(Duration(days: index)),
  );
}

List<Task> _getDailyTasks(List<Task> tasks, DateTime date) {
  final formattedDate = DateFormat('yyyy-MM-dd').format(date);
  return tasks.where((task) => task.date == formattedDate).toList();
}

List<Task> _getWeeklyTasks(List<Task> tasks, DateTime date) {
  // Start from Sunday
  final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return tasks.where((task) {
    final taskDate = DateTime.parse(task.date);
    final normalizedTaskDate = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
    );
    final normalizedStartDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final normalizedEndDate = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
    );

    return normalizedTaskDate.isAtSameMomentAs(normalizedStartDate) ||
        normalizedTaskDate.isAtSameMomentAs(normalizedEndDate) ||
        (normalizedTaskDate.isAfter(
              normalizedStartDate.subtract(const Duration(days: 1)),
            ) &&
            normalizedTaskDate.isBefore(
              normalizedEndDate.add(const Duration(days: 1)),
            ));
  }).toList();
}

List<Task> _getMonthlyTasks(List<Task> tasks, DateTime date) {
  final startOfMonth = DateTime(date.year, date.month, 1);
  final endOfMonth = DateTime(date.year, date.month + 1, 0);

  return tasks.where((task) {
    final taskDate = DateTime.parse(task.date);
    final normalizedTaskDate = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
    );
    final normalizedStartDate = DateTime(
      startOfMonth.year,
      startOfMonth.month,
      startOfMonth.day,
    );
    final normalizedEndDate = DateTime(
      endOfMonth.year,
      endOfMonth.month,
      endOfMonth.day,
    );

    return normalizedTaskDate.isAtSameMomentAs(normalizedStartDate) ||
        normalizedTaskDate.isAtSameMomentAs(normalizedEndDate) ||
        (normalizedTaskDate.isAfter(
              normalizedStartDate.subtract(const Duration(days: 1)),
            ) &&
            normalizedTaskDate.isBefore(
              normalizedEndDate.add(const Duration(days: 1)),
            ));
  }).toList();
}

PerformanceMetrics _calculateMetrics(
  List<Task> tasks,
  List<DateTime> dateRange,
) {
  // Initialize daily stats for all dates in range
  final dailyStats = {
    for (var date in dateRange)
      DateTime(date.year, date.month, date.day): DailyCompletion(
        date: DateFormat('MMM d').format(date),
        dayName: DateFormat('E').format(date),
      ),
  };

  final importanceDistribution = <int, int>{};
  var totalTasks = 0;
  var completedTasks = 0;

  // Process all tasks
  for (final task in tasks) {
    final taskDate = DateTime.parse(task.date);
    final normalizedDate = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
    );

    if (dailyStats.containsKey(normalizedDate)) {
      dailyStats[normalizedDate]!.total++;
      if (task.completed) {
        dailyStats[normalizedDate]!.completed++;
        completedTasks++;
      }

      importanceDistribution.update(
        task.importance,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      totalTasks++;
    }
  }

  // Calculate average completion rate
  final averageCompletionRate =
      totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

  // Convert to sorted list
  final sortedDailyStats =
      dailyStats.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  return PerformanceMetrics(
    dailyCompletion: sortedDailyStats.map((e) => e.value).toList(),
    importanceDistribution: importanceDistribution,
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    averageCompletionRate: averageCompletionRate,
  );
}

// Models
class DailyCompletion {
  final String date;
  final String dayName; // Added day name
  int total = 0;
  int completed = 0;

  DailyCompletion({
    required this.date,
    required this.dayName,
    this.total = 0,
    this.completed = 0,
  });
}

class PerformanceMetrics {
  final List<DailyCompletion> dailyCompletion;
  final Map<int, int> importanceDistribution;
  final int totalTasks;
  final int completedTasks;
  final double averageCompletionRate;

  const PerformanceMetrics({
    required this.dailyCompletion,
    required this.importanceDistribution,
    required this.totalTasks,
    required this.completedTasks,
    required this.averageCompletionRate,
  });

  factory PerformanceMetrics.empty() {
    return const PerformanceMetrics(
      dailyCompletion: [],
      importanceDistribution: {},
      totalTasks: 0,
      completedTasks: 0,
      averageCompletionRate: 0,
    );
  }
}
