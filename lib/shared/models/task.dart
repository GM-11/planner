import 'package:planner/shared/services/supabase_service.dart';

class Task {
  final int? id; // Make id nullable for new tasks
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

  Task copyWith({
    int? id,
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

  Map<String, dynamic> toJson() {
    return {
      // Only include id for updates, not for inserts
      if (id != null) 'id': id,
      'text': text,
      'start_time': startTime,
      'end_time': endTime,
      'date': date,
      'completed': completed,
      'importance': importance,
      'user_id': SupabaseService.client.auth.currentUser!.id,
    };
  }

  // Create a separate method for updates
  Map<String, dynamic> toUpdateJson() {
    return {
      'text': text,
      'start_time': startTime,
      'end_time': endTime,
      'date': date,
      'completed': completed,
      'importance': importance,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      text: json['text'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      date: json['date'] as String,
      completed: json['completed'] as bool,
      importance: json['importance'] as int,
    );
  }
}
