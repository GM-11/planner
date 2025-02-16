import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:planner/shared/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/constant.dart';
import '../../../shared/models/task.dart';
import "package:http/http.dart" as http;

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

class TasksRepository {
  final _supabase = SupabaseService.client;

  Future<List<Task>> getTasksForDate(String date) async {
    try {
      final response =
          await _supabase
              .from('tasks')
              .select()
              .eq('user_id', _supabase.auth.currentUser!.id)
              .eq('date', date)
              .maybeSingle();

      if (response == null) {
        return [];
      }

      final tasksData = response['data'] as List;
      return tasksData.map((taskJson) {
          // Ensure each task has an ID
          if (taskJson['id'] == null) {
            taskJson['id'] =
                const Uuid().v4(); // Add UUID package to pubspec.yaml
          }
          return Task.fromJson({
            ...taskJson as Map<String, dynamic>,
            'date': date,
          });
        }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      log('Error fetching tasks for date: $e');
      rethrow;
    }
  }

  Future<List<Task>> getAllTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('date', ascending: true);

      List<Task> allTasks = [];

      for (final record in response) {
        final date = record['date'] as String;
        final tasksData = record['data'] as List;

        final dayTasks =
            tasksData.map((taskJson) {
              return Task.fromJson({
                ...taskJson as Map<String, dynamic>,
                'date': date,
              });
            }).toList();

        allTasks.addAll(dayTasks);
      }

      return allTasks..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      log('Error fetching all tasks: $e');
      rethrow;
    }
  }

  Future<void> addTask(Task task) async {
    final userId = _supabase.auth.currentUser!.id;

    try {
      // Generate a new ID for the task if it doesn't have one
      final taskData = task.toJson();
      if (taskData['id'] == null) {
        taskData['id'] = const Uuid().v4();
      }
      taskData.remove('date'); // Remove date as it's stored at record level

      final existingRecord =
          await _supabase
              .from('tasks')
              .select()
              .eq('user_id', userId)
              .eq('date', task.date)
              .maybeSingle();

      if (existingRecord != null) {
        final existingTasks =
            (existingRecord['data'] as List).map((t) {
              if (t['id'] == null) {
                t['id'] = const Uuid().v4();
              }
              return Task.fromJson({
                ...t as Map<String, dynamic>,
                'date': task.date,
              });
            }).toList();

        final updatedTasks = [...existingTasks, task];

        await _supabase
            .from('tasks')
            .update({
              'data':
                  updatedTasks.map((t) {
                    final json = t.toJson();
                    json.remove('date');
                    return json;
                  }).toList(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('date', task.date);
      } else {
        await _supabase.from('tasks').insert({
          'user_id': userId,
          'date': task.date,
          'data': [taskData],
        });
      }

      scheduleNotifiction(task, _supabase, userId);
    } catch (e) {
      log('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final record =
          await _supabase
              .from('tasks')
              .select()
              .eq('user_id', userId)
              .eq('date', task.date)
              .single();

      final existingTasks =
          (record['data'] as List)
              .map(
                (t) => Task.fromJson({
                  ...t as Map<String, dynamic>,
                  'date': task.date,
                }),
              )
              .toList();

      final updatedTasks =
          existingTasks.map((t) {
            if (t.id == task.id) {
              return task;
            }
            return t;
          }).toList();

      await _supabase
          .from('tasks')
          .update({
            'data':
                updatedTasks.map((t) {
                  final json = t.toJson();
                  json.remove('date'); // Remove date from individual tasks
                  return json;
                }).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('date', task.date);
    } catch (e) {
      log('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Get the current record for this date
      final record =
          await _supabase
              .from('tasks')
              .select()
              .eq('user_id', userId)
              .eq('date', task.date)
              .single();

      // Get the current tasks array
      final tasksData = record['data'] as List;

      // Filter out the task to delete
      final remainingTasks =
          tasksData.where((taskJson) {
            // Compare task properties since we might not have reliable IDs
            return taskJson['text'] != task.text ||
                taskJson['start_time'] != task.startTime ||
                taskJson['end_time'] != task.endTime;
          }).toList();

      if (remainingTasks.isEmpty) {
        // If no tasks left, delete the entire record
        await _supabase
            .from('tasks')
            .delete()
            .eq('user_id', userId)
            .eq('date', task.date);
      } else {
        // Update with remaining tasks
        await _supabase
            .from('tasks')
            .update({
              'data': remainingTasks,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('date', task.date);
      }
    } catch (e) {
      log('Error deleting task: $e');
      rethrow;
    }
  }
}

String formatDateTime(DateTime dateTime) {
  // Get timezone offset in hours and minutes
  Duration offset = dateTime.timeZoneOffset;
  String sign = offset.isNegative ? "-" : "+";
  int hours = offset.inHours.abs();
  int minutes = offset.inMinutes.abs() % 60;

  // Format timezone as GMT±hhmm
  String timezone =
      "GMT$sign${hours.toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}";

  // Format the datetime
  String formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);

  return "$formattedDate $timezone";
}

DateTime _parseTaskTime(String date, String time) {
  final timeComponents = time.split(':');
  final hour = int.parse(timeComponents[0]);
  final minute = int.parse(timeComponents[1]);
  return DateTime.parse(date).add(Duration(hours: hour, minutes: minute));
}

void scheduleNotifiction(
  Task task,
  SupabaseClient supabase,
  String userId,
) async {
  final scheduledTime = _parseTaskTime(task.date, task.startTime);

  var oneSignalUserId = "";
  if (!Platform.isLinux) {
    oneSignalUserId = (await OneSignal.User.getOnesignalId())!;
  }

  var signalIds = await supabase
      .from("user_devices")
      .select()
      .eq("user_id", userId);

  log(signalIds.toString());
  final uri = Uri.parse("https://api.onesignal.com/notifications?c=push");

  final signalIdsList = signalIds[0]['signal_ids'].toString().split(
    AppConstants.delimeter,
  );

  var list = [...signalIdsList, oneSignalUserId];
  final finalList = list.where((element) => element.isNotEmpty).toList();
  await dotenv.load(fileName: ".env");
  var res = await http.post(
    uri,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Basic ${dotenv.env["ONE_SIGNAL_API_KEY"]!}",
      "Accept": "application/json",
    },
    body: jsonEncode({
      "app_id": dotenv.env["ONE_SIGNAL_APP_ID"]!,
      "contents": {"en": "Time for '${task.text}'"},
      "include_aliases": {"onesignal_id": finalList},
      "send_after": formatDateTime(scheduledTime),
      "target_channel": "push",
    }),
  );

  log(res.body);
}
