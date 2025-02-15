import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:planner/shared/constant.dart';
import '../../../shared/models/task.dart';

class AddTaskModal extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Function(Task) onAdd;
  final String? initialTime;

  const AddTaskModal({
    super.key,
    required this.selectedDate,
    required this.onAdd,
    this.initialTime,
  });

  @override
  ConsumerState<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends ConsumerState<AddTaskModal> {
  final _textController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  int _importance = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTime != null) {
      final timeParts = widget.initialTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      _endTime = TimeOfDay(
        hour: (_startTime.hour + 1) % 24,
        minute: _startTime.minute,
      );
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // If end time is before start time, adjust it
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour &&
                  _endTime.minute < _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: _startTime.hour,
              minute: _startTime.minute + 30,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a task name')));
      return;
    }

    final task = Task(
      id: null,
      text: _textController.text,
      startTime:
          '${_startTime.hour.toString().padLeft(2, '0')}:'
          '${_startTime.minute.toString().padLeft(2, '0')}',
      endTime:
          '${_endTime.hour.toString().padLeft(2, '0')}:'
          '${_endTime.minute.toString().padLeft(2, '0')}',
      date: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      completed: false,
      importance: _importance,
    );

    widget.onAdd(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          width: isDesktop ? 400 : double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Add New Task',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Ionicons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTaskNameField(),
              const SizedBox(height: 24),
              _buildTimeFields(),
              const SizedBox(height: 24),
              _buildImportanceSlider(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Name',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Enter task name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Time',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_startTime.format(context)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'End Time',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_endTime.format(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppConstants.importanceColors[_importance],
            inactiveTrackColor: Colors.grey[200],
            thumbColor: AppConstants.importanceColors[_importance],
          ),
          child: Slider(
            value: _importance.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            onChanged: (value) => setState(() => _importance = value.toInt()),
          ),
        ),
        Center(
          child: Text(
            AppConstants.importanceLevels[_importance].replaceAll('-', ' '),
            style: TextStyle(
              color: AppConstants.importanceColors[_importance],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
