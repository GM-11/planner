import 'package:planner/shared/services/supabase_service.dart';

class Task {
  final String? id; // Change to String type
  final String text;
  final String startTime;
  final String endTime;
  final String date;
  final bool completed;
  final int importance;

  Task({
    this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.completed,
    required this.importance,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString(), // Convert to String
      text: json['text'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      date: json['date'] as String,
      completed: json['completed'] as bool,
      importance: json['importance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'text': text,
      'start_time': startTime,
      'end_time': endTime,
      'date': date,
      'completed': completed,
      'importance': importance,
    };
  }

  Task copyWith({
    String? id,
    String? text,
    String? startTime,
    String? endTime,
    String? date,
    bool? completed,
    int? importance,
  }) {
    return Task(
      id: id ?? this.id,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      importance: importance ?? this.importance,
    );
  }
}

class TaskDate {
  final String date;
  final List<Task> tasks;

  TaskDate({required this.date, required this.tasks});

  factory TaskDate.fromJson(Map<String, dynamic> json) {
    return TaskDate(
      date: json['date'],
      tasks: (json['data'] as List).map((task) => Task.fromJson(task)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'data': tasks.map((task) => task.toJson()).toList()};
  }
}
