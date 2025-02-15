import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/task.dart';
import '../repositories/tasks_repository.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Main tasks provider that always fetches fresh data
final tasksStateProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  return repository.getAllTasks();
});

// Filtered tasks provider
final tasksForDateProvider = Provider.autoDispose<AsyncValue<List<Task>>>((
  ref,
) {
  final selectedDate = ref.watch(selectedDateProvider);
  final tasksAsync = ref.watch(tasksStateProvider);

  return tasksAsync.when(
    data: (tasks) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final filteredTasks =
          tasks.where((task) => task.date == formattedDate).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return AsyncValue.data(filteredTasks);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

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
    await _repository.addTask(task);
    _ref.invalidate(tasksStateProvider);
  }

  Future<void> toggleTask(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    await _repository.updateTask(updatedTask);
    _ref.invalidate(tasksStateProvider);
  }

  Future<void> deleteTask(Task task) async {
    if (task.id != null) {
      await _repository.deleteTask(task.id!);
      _ref.invalidate(tasksStateProvider);
    }
  }
}
