import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:planner/shared/services/supabase_service.dart';

import '../../../shared/constant.dart';
import '../../../shared/models/task.dart';
import "package:http/http.dart" as http;

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

class TasksRepository {
  final _supabase = SupabaseService.client;

  Future<List<Task>> getAllTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('date', ascending: true)
          .order('start_time', ascending: true);

      return (response as List).map((task) => Task.fromJson(task)).toList();
    } catch (e) {
      log('Error fetching tasks: $e');
      rethrow;
    }
  }

  Future<Task> addTask(Task task) async {
    final userId = _supabase.auth.currentUser!.id;
    final response =
        await _supabase
            .from('tasks')
            .insert({
              'text': task.text,
              'start_time': task.startTime,
              'end_time': task.endTime,
              'date': task.date,
              'completed': task.completed,
              'importance': task.importance,
              'user_id': userId,
            })
            .select()
            .single();

    final newTask = Task.fromJson(response);

    final scheduledTime = _parseTaskTime(task.date, task.startTime);

    var oneSignalUserId = "";
    if (!Platform.isLinux) {
      oneSignalUserId = (await OneSignal.User.getOnesignalId())!;
    }

    var signalIds = await _supabase
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
        "Authorization":
            "Basic ${dotenv.env["ONE_SIGNAL_API_KEY"]!}",
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
    return newTask;
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;

    await _supabase
        .from('tasks')
        .update(task.toUpdateJson())
        .eq('id', task.id!);
  }

  Future<void> deleteTask(int taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  DateTime _parseTaskTime(String date, String time) {
    final timeComponents = time.split(':');
    final hour = int.parse(timeComponents[0]);
    final minute = int.parse(timeComponents[1]);
    return DateTime.parse(date).add(Duration(hours: hour, minutes: minute));
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
