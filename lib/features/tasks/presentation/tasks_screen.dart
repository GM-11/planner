import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:planner/features/tasks/presentation/add_task_modal.dart';
import 'package:planner/features/tasks/presentation/tasks_shimmer.dart';
import 'package:planner/shared/constant.dart';
import '../../../shared/models/task.dart';
import '../../../shared/widgets/date_navigator.dart';
import '../providers/tasks_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  void _showAddTaskSheet() {
    showDialog(
      context: context,
      builder:
          (context) => AddTaskModal(
            selectedDate: ref.read(selectedDateProvider),
            onAdd: (task) async {
              try {
                await ref.read(taskOperationsProvider).addTask(task);
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding task: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Ionicons.calendar_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tasksForDateProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TaskCard(
              task: task,
              onToggle: () => ref.read(taskOperationsProvider).toggleTask(task),
              onDelete: () => ref.read(taskOperationsProvider).deleteTask(task),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final sortedTasksAsync = ref.watch(sortedTasksProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      body:
          isDesktop
              ? _buildDesktopLayout(context, selectedDate, sortedTasksAsync)
              : _buildMobileLayout(context, selectedDate, sortedTasksAsync),
      floatingActionButton:
          !isDesktop
              ? FloatingActionButton(
                onPressed: _showAddTaskSheet,
                backgroundColor: Theme.of(context).primaryColor,
                child: Icon(Ionicons.add, color: Theme.of(context).canvasColor),
              )
              : null,
    );
  }

  Widget _buildSortControls({bool isDark = false}) {
    final sorting = ref.watch(taskSortingProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Row(
            children: [
              _buildSortChip(
                title: 'Time',
                isSelected: sorting.type == 'time',
                onTap:
                    () =>
                        ref.read(taskSortingProvider.notifier).state = sorting
                            .copyWith(type: 'time'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                title: 'Priority',
                isSelected: sorting.type == 'importance',
                onTap:
                    () =>
                        ref.read(taskSortingProvider.notifier).state = sorting
                            .copyWith(type: 'importance'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildOrderButton(sorting: sorting, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? isDark
                      ? Colors.black.withAlpha(25)
                      : Colors.white.withAlpha(12)
                  : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.white70
                    : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderButton({required TaskSort sorting, required bool isDark}) {
    return InkWell(
      onTap:
          () =>
              ref.read(taskSortingProvider.notifier).state = sorting.copyWith(
                ascending: !sorting.ascending,
              ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          sorting.ascending ? Ionicons.arrow_up : Ionicons.arrow_down,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSortButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.white.withAlpha(25)
                  : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    DateTime selectedDate,
    AsyncValue<List<Task>> tasksAsync,
  ) {
    final sorting = ref.watch(taskSortingProvider);

    return Row(
      children: [
        // Left sidebar
        Container(
          width: 400,
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Task Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              DateNavigator(
                selectedDate: selectedDate,
                onDateChange: (date) {
                  ref.read(selectedDateProvider.notifier).state = date;
                },
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSortButton(
                      title: 'Time',
                      isSelected: sorting.type == 'time',
                      onTap:
                          () =>
                              ref
                                  .read(taskSortingProvider.notifier)
                                  .state = sorting.copyWith(type: 'time'),
                    ),
                    const SizedBox(height: 8),
                    _buildSortButton(
                      title: 'Priority',
                      isSelected: sorting.type == 'importance',
                      onTap:
                          () =>
                              ref
                                  .read(taskSortingProvider.notifier)
                                  .state = sorting.copyWith(type: 'importance'),
                    ),
                    const SizedBox(height: 8),
                    _buildSortButton(
                      title: 'Order',
                      isSelected: false,
                      onTap:
                          () =>
                              ref
                                  .read(taskSortingProvider.notifier)
                                  .state = sorting.copyWith(
                                ascending: !sorting.ascending,
                              ),
                      trailing: Icon(
                        sorting.ascending
                            ? Ionicons.arrow_up
                            : Ionicons.arrow_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddTaskSheet,
                      icon: const Icon(Ionicons.add, color: Colors.white),
                      label: const Text('Add New Task'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) => _buildTasksList(tasks),
                  loading: () => const TasksShimmer(isDesktop: true),
                  error:
                      (error, stack) =>
                          Center(child: Text('Error: ${error.toString()}')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    DateTime selectedDate,
    AsyncValue<List<Task>> tasksAsync,
  ) {
    return Column(
      children: [
        // Header section with purple background
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DateNavigator(
                  selectedDate: selectedDate,
                  onDateChange: (date) {
                    ref.read(selectedDateProvider.notifier).state = date;
                  },
                ),
                _buildSortControls(isDark: true),
              ],
            ),
          ),
        ),
        // Tasks list
        Expanded(
          child: tasksAsync.when(
            data: (tasks) => _buildTasksList(tasks),
            loading: () => const TasksShimmer(isDesktop: false),
            error:
                (error, stack) =>
                    Center(child: Text('Error: ${error.toString()}')),
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppConstants.importanceColors[task.importance],
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildCheckbox(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration:
                              task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                          color: task.completed ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.startTime} - ${task.endTime}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Ionicons.trash_outline,
                    color: Colors.red[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(
          color:
              task.completed
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: task.completed ? Theme.of(context).primaryColor : null,
      ),
      child:
          task.completed
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
    );
  }
}
