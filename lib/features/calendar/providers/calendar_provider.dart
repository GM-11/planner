import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/task.dart';
import '../../tasks/providers/tasks_provider.dart';

enum CalendarViewType { daily, weekly, monthly }

final calendarViewTypeProvider = StateProvider<CalendarViewType>(
  (ref) => CalendarViewType.daily,
);

final calendarSelectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final weekDatesProvider = Provider<List<DateTime>>((ref) {
  final selectedDate = ref.watch(calendarSelectedDateProvider);
  // Calculate the start of week (Sunday)
  final startOfWeek = selectedDate.subtract(
    Duration(days: selectedDate.weekday % 7),
  );

  // Generate dates from Sunday to Saturday
  final dates = List.generate(
    7,
    (index) => startOfWeek.add(Duration(days: index)),
  );

  // Debug print

  return dates;
});

final calendarTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((
  ref,
) {
  final viewType = ref.watch(calendarViewTypeProvider);
  final selectedDate = ref.watch(calendarSelectedDateProvider);
  final tasksAsync = ref.watch(tasksStateProvider);

  ref.keepAlive();

  return tasksAsync.when(
    data: (tasks) {
      switch (viewType) {
        case CalendarViewType.daily:
          final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
          return AsyncValue.data(
            tasks.where((task) => task.date == formattedDate).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime)),
          );

        case CalendarViewType.weekly:
          final weekDates = ref.read(weekDatesProvider);

          // Debug prints

          final weekTasks =
              tasks.where((task) {
                  final formattedWeekDates =
                      weekDates
                          .map((date) => DateFormat('yyyy-MM-dd').format(date))
                          .toList();

                  final isInWeek = formattedWeekDates.contains(task.date);

                  return isInWeek;
                }).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return AsyncValue.data(weekTasks);

        case CalendarViewType.monthly:
          final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
          final monthEnd = DateTime(
            selectedDate.year,
            selectedDate.month + 1,
            0,
          );
          final monthTasks =
              tasks.where((task) {
                  final taskDate = DateTime.parse(task.date);
                  return taskDate.isAfter(
                        monthStart.subtract(const Duration(days: 1)),
                      ) &&
                      taskDate.isBefore(monthEnd.add(const Duration(days: 1)));
                }).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
          return AsyncValue.data(monthTasks);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final filteredTasksProvider = Provider.family<List<Task>, DateTime>((
  ref,
  date,
) {
  final tasksAsync = ref.watch(calendarTasksProvider);

  return tasksAsync.when(
    data: (tasks) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      return tasks.where((task) => task.date == formattedDate).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Optional: Add a caching layer for filtered tasks
final cachedFilteredTasksProvider = Provider.family<List<Task>, String>((
  ref,
  date,
) {
  final tasks = ref.watch(filteredTasksProvider(DateTime.parse(date)));
  return tasks;
});
