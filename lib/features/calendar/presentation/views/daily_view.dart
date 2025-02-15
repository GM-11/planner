import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/add_task_model.dart';
import '../../../../shared/widgets/date_navigator.dart';
import '../../../../shared/models/task.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/current_time_line.dart';

class DailyView extends ConsumerWidget {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);

    return Column(
      children: [
        DateNavigator(
          selectedDate: selectedDate,
          onDateChange: (date) {
            ref.read(calendarSelectedDateProvider.notifier).state = date;
          },
          isDark: false,
        ),
        Expanded(
          child: tasksAsync.when(
            data:
                (tasks) => TimeGrid(
                  tasks: tasks,
                  selectedDate: selectedDate,
                  showCurrentTimeLine: true,
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class TimeGrid extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final DateTime selectedDate;
  final bool showCurrentTimeLine;

  const TimeGrid({
    required this.tasks,
    required this.selectedDate,
    this.showCurrentTimeLine = false,
    super.key,
  });

  @override
  ConsumerState<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends ConsumerState<TimeGrid> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: TimeOfDay.now().hour * 80.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        // Add this SizedBox to give the Stack a defined size
        height: 24 * 80, // 24 hours * 80 pixels per hour
        child: Stack(
          children: [
            // Time slots background
            Column(
              children: List.generate(
                24,
                (hour) => _buildTimeSlotBackground(hour),
              ),
            ),
            // Tasks
            ...widget.tasks.map((task) => _buildTaskCard(context, task)),
            // Current time line
            if (widget.showCurrentTimeLine &&
                isSameDay(widget.selectedDate, DateTime.now()))
              const CurrentTimeLine(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotBackground(int hour) {
    return InkWell(
      onTap: () {
        final formattedHour = hour.toString().padLeft(2, '0');
        showAddTaskModal(
          context,
          ref,
          widget.selectedDate,
          initialTime: '$formattedHour:00',
        );
      },
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatHour(hour),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final startHour = int.parse(task.startTime.split(':')[0]);
    final startMinute = int.parse(task.startTime.split(':')[1]);
    final endHour = int.parse(task.endTime.split(':')[0]);
    final endMinute = int.parse(task.endTime.split(':')[1]);

    final totalStartMinutes = startHour * 60 + startMinute;
    final totalEndMinutes = endHour * 60 + endMinute;
    final durationInMinutes = totalEndMinutes - totalStartMinutes;

    final top = (totalStartMinutes * 80) / 60;
    final height = (durationInMinutes * 80) / 60;

    return Positioned(
      top: top,
      left: 70,
      right: 0,
      height: height,
      child: _TaskCard(task: task, height: height, key: ValueKey(task.id)),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final double height;

  const _TaskCard({required this.task, required this.height, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompact = height <= 45;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            task.completed
                ? Colors.grey.shade800
                : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isCompact ? _buildCompactView() : _buildFullView(),
    );
  }

  Widget _buildCompactView() {
    return SingleChildScrollView(
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${task.startTime} - ${task.endTime}',
            style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Text(
          '${task.startTime} - ${task.endTime}',
          style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 10),
        ),
      ],
    );
  }
}

bool isSameDay(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}
