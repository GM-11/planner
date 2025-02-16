import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/task.dart';
import '../repositories/tasks_repository.dart';

// Selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Main tasks state provider
final tasksStateProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final cacheKey = ref.watch(_tasksCacheKeyProvider);

  // Use cache key to invalidate cache when needed
  ref.keepAlive();
  return repository.getAllTasks();
});

// Provider for tasks on the selected date
final tasksForDateProvider = FutureProvider.autoDispose<List<Task>>((
  ref,
) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

  return repository.getTasksForDate(formattedDate);
});

// Cache key provider for managing cache invalidation
final _tasksCacheKeyProvider = StateProvider<int>((ref) => 0);

// Task operations provider
final taskOperationsProvider = Provider((ref) {
  final repository = ref.watch(tasksRepositoryProvider);
  return TaskOperations(ref, repository);
});

class TaskOperations {
  final Ref _ref;
  final TasksRepository _repository;

  TaskOperations(this._ref, this._repository);

  Future<void> addTask(Task task) async {
    try {
      await _repository.addTask(task);
      _invalidateCache();
    } catch (e) {
      log('Failed to add task: $e');
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> toggleTask(Task task) async {
    try {
      final updatedTask = task.copyWith(completed: !task.completed);
      await _repository.updateTask(updatedTask);
      _invalidateCache();
    } catch (e) {
      log('Failed to update task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _repository.deleteTask(task);
      _invalidateCache();
    } catch (e) {
      log('Failed to delete task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  void _invalidateCache() {
    // Increment cache key to invalidate all cached data
    _ref.read(_tasksCacheKeyProvider.notifier).state++;
    // Invalidate current date's tasks
    _ref.invalidate(tasksStateProvider);
    _ref.invalidate(tasksForDateProvider);
  }
}

// Task sorting provider
final taskSortingProvider = StateProvider<TaskSort>((ref) => const TaskSort());

class TaskSort {
  final String type;
  final bool ascending;

  const TaskSort({this.type = 'time', this.ascending = true});

  TaskSort copyWith({String? type, bool? ascending}) {
    return TaskSort(
      type: type ?? this.type,
      ascending: ascending ?? this.ascending,
    );
  }
}

// Sorted tasks provider
final sortedTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final tasks = await ref.watch(tasksForDateProvider.future);
  final sorting = ref.watch(taskSortingProvider);

  final sortedTasks = List<Task>.from(tasks);
  sortedTasks.sort((a, b) {
    if (sorting.type == 'time') {
      final comparison = a.startTime.compareTo(b.startTime);
      return sorting.ascending ? comparison : -comparison;
    } else {
      final comparison = b.importance.compareTo(a.importance);
      return sorting.ascending ? -comparison : comparison;
    }
  });

  return sortedTasks;
});

// Statistics providers
final taskStatsProvider = FutureProvider.autoDispose<TaskStats>((ref) async {
  final tasks = await ref.watch(tasksForDateProvider.future);

  return TaskStats(
    total: tasks.length,
    completed: tasks.where((t) => t.completed).length,
    highPriority: tasks.where((t) => t.importance >= 2).length,
  );
});

final weeklyStatsProvider = FutureProvider.autoDispose<WeeklyStats>((
  ref,
) async {
  final repository = ref.watch(tasksRepositoryProvider);
  final today = DateTime.now();
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  final weeklyTasks = <Task>[];

  // Fetch tasks for each day of the week
  for (var i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final dayTasks = await repository.getTasksForDate(formattedDate);
    weeklyTasks.addAll(dayTasks);
  }

  return WeeklyStats(
    totalTasks: weeklyTasks.length,
    completedTasks: weeklyTasks.where((t) => t.completed).length,
    tasksPerDay: Map.fromEntries(
      List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        return MapEntry(
          formattedDate,
          weeklyTasks.where((t) => t.date == formattedDate).length,
        );
      }),
    ),
  );
});

// Stats models
class TaskStats {
  final int total;
  final int completed;
  final int highPriority;

  TaskStats({
    required this.total,
    required this.completed,
    required this.highPriority,
  });

  double get completionRate => total > 0 ? completed / total : 0;
}

class WeeklyStats {
  final int totalTasks;
  final int completedTasks;
  final Map<String, int> tasksPerDay;

  WeeklyStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.tasksPerDay,
  });

  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0;
  double get averageTasksPerDay => totalTasks / 7;
}
