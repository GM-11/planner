import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:planner/shared/widgets/add_task_model.dart'
    show showAddTaskModal;
import '../../../../shared/models/task.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/current_time_line.dart';

class WeeklyView extends ConsumerWidget {
  const WeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final weekDates = ref.watch(weekDatesProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);

    return Column(
      children: [
        _WeekHeader(
          weekDates: weekDates,
          selectedDate: selectedDate,
          onDateSelected: (date) {
            ref.read(calendarSelectedDateProvider.notifier).state = date;
          },
        ),
        Expanded(
          child: tasksAsync.when(
            data:
                (tasks) => _WeeklyTimeGrid(
                  tasks: tasks,
                  weekDates: weekDates,
                  selectedDate: selectedDate,
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final List<DateTime> weekDates;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _WeekHeader({
    required this.weekDates,
    required this.selectedDate,
    required this.onDateSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final startOfWeek = weekDates.first;
    final endOfWeek = weekDates.last;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Week navigation controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final previousWeek = startOfWeek.subtract(
                      const Duration(days: 7),
                    );
                    onDateSelected(previousWeek);
                  },
                ),
                Text(
                  '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final nextWeek = startOfWeek.add(const Duration(days: 7));
                    onDateSelected(nextWeek);
                  },
                ),
              ],
            ),
          ),
          // Days of the week
          Row(
            children: [
              const SizedBox(width: 64),
              ...weekDates.map(
                (date) => Expanded(
                  child: _WeekDayHeader(
                    date: date,
                    isSelected: isSameDay(date, selectedDate),
                    onTap: () => onDateSelected(date),
                    key: ValueKey(date),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayHeader extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeekDayHeader({
    required this.date,
    required this.isSelected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(date, DateTime.now());

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration:
                  isToday
                      ? BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      )
                      : null,
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTimeGrid extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final List<DateTime> weekDates;
  final DateTime selectedDate;

  const _WeeklyTimeGrid({
    required this.tasks,
    required this.weekDates,
    required this.selectedDate,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<_WeeklyTimeGrid> createState() => _WeeklyTimeGridState();
}

class _WeeklyTimeGridState extends ConsumerState<_WeeklyTimeGrid> {
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
      child: LayoutBuilder(
        // Add LayoutBuilder here
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final columnWidth =
              (availableWidth - 64) / 7; // Calculate column width

          return SizedBox(
            height: 24 * 80, // 24 hours * 80 pixels per hour
            child: Stack(
              children: [
                _buildTimeSlots(columnWidth),
                ...widget.weekDates.asMap().entries.map((entry) {
                  final dayIndex = entry.key;
                  final date = entry.value;
                  return _buildDayTasks(date, dayIndex, columnWidth);
                }),
                if (widget.weekDates.any(
                  (date) => isSameDay(date, DateTime.now()),
                ))
                  const CurrentTimeLine(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots(double columnWidth) {
    return Column(
      children: List.generate(
        24,
        (hour) => Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
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
              ...List.generate(
                7,
                (dayIndex) => Expanded(
                  child: InkWell(
                    onTap: () {
                      final date = widget.weekDates[dayIndex];
                      final formattedHour = hour.toString().padLeft(2, '0');
                      showAddTaskModal(
                        context,
                        ref,
                        date,
                        initialTime: '$formattedHour:00',
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayTasks(DateTime date, int dayIndex, double columnWidth) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final dayTasks =
        widget.tasks.where((task) => task.date == formattedDate).toList();

    return Stack(
      children:
          dayTasks.map((task) {
            final timeSlot = _calculateTimeSlot(task);
            final leftPosition = 64 + (dayIndex * columnWidth);

            return Positioned(
              top: timeSlot.top,
              left: leftPosition,
              width: columnWidth - 8, // Leave some padding
              height: timeSlot.height,
              child: _TaskCard(
                task: task,
                compactView: timeSlot.height <= 40,
                key: ValueKey(task.id),
              ),
            );
          }).toList(),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class _TimeSlot {
  final double top;
  final double height;

  const _TimeSlot({required this.top, required this.height});
}

_TimeSlot _calculateTimeSlot(Task task) {
  final startHour = int.parse(task.startTime.split(':')[0]);
  final startMinute = int.parse(task.startTime.split(':')[1]);
  final endHour = int.parse(task.endTime.split(':')[0]);
  final endMinute = int.parse(task.endTime.split(':')[1]);

  final totalStartMinutes = startHour * 60 + startMinute;
  final totalEndMinutes = endHour * 60 + endMinute;
  final durationInMinutes = totalEndMinutes - totalStartMinutes;

  final top = (totalStartMinutes * 80) / 60;
  final height = (durationInMinutes * 80) / 60;

  return _TimeSlot(top: top, height: height);
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool compactView;

  const _TaskCard({required this.task, this.compactView = false, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            task.completed
                ? Colors.grey.shade800
                : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: compactView ? _buildCompactView(context) : _buildFullView(context),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context) {
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${task.startTime} - ${task.endTime}',
          style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
