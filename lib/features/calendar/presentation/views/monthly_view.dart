import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../shared/models/task.dart';
import '../../../../shared/widgets/add_task_model.dart';
import '../../providers/calendar_provider.dart';

class MonthlyView extends ConsumerWidget {
  const MonthlyView({super.key});

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

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);

    return Row(
      children: [
        SizedBox(
          width: 400,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Tasks for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: tasksAsync.when(
                    data:
                        (tasks) => _TaskList(
                          tasks: ref.watch(filteredTasksProvider(selectedDate)),
                        ),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stack) => Center(child: Text('Error: $error')),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _Calendar(
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(calendarSelectedDateProvider.notifier).state =
                  selectedDay;
            },
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(calendarTasksProvider);
    final selectedDate = ref.watch(calendarSelectedDateProvider);

    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          child: Column(
            children: [
              _Calendar(
                onDaySelected: (selectedDay, focusedDay) {
                  ref.read(calendarSelectedDateProvider.notifier).state =
                      selectedDay;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tasks for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              tasksAsync.when(
                data:
                    (tasks) => _TaskListContent(
                      tasks: ref.watch(filteredTasksProvider(selectedDate)),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
              // Add padding at the bottom for FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              showAddTaskModal(context, ref, selectedDate);
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _TaskListContent extends StatelessWidget {
  final List<Task> tasks;

  const _TaskListContent({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No tasks for this day',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, // Important to work inside SingleChildScrollView
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling of ListView
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(task: task, key: ValueKey(task.id));
      },
    );
  }
}

class _Calendar extends ConsumerWidget {
  final Function(DateTime, DateTime) onDaySelected;

  const _Calendar({required this.onDaySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(calendarSelectedDateProvider);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2025, 12, 31),
          focusedDay: selectedDate,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          onDaySelected: onDaySelected, // Remove the add task modal here
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(color: Colors.white),
            todayTextStyle: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          availableGestures: AvailableGestures.horizontalSwipe,
          calendarBuilders: const CalendarBuilders(),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;

  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks for this day',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(task: task, key: ValueKey(task.id));
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(
            color:
                task.completed
                    ? Colors.grey.shade400
                    : Theme.of(context).primaryColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? Colors.grey : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${task.startTime} - ${task.endTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

bool isSameDay(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}
