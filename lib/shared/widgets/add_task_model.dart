import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tasks/presentation/add_task_modal.dart';
import '../../features/tasks/providers/tasks_provider.dart';

void showAddTaskModal(
  BuildContext context,
  WidgetRef ref,
  DateTime selectedDate, {
  String? initialTime,
}) {
  showDialog(
    context: context,
    builder:
        (context) => AddTaskModal(
          selectedDate: selectedDate,
          initialTime: initialTime,
          onAdd: (task) async {
            try {
              await ref.read(taskOperationsProvider).addTask(task);
              if (context.mounted) {
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding task: ${e.toString()}')),
                );
              }
            }
          },
        ),
  );
}
