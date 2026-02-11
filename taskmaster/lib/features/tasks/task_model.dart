import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  TaskStatus status;

  @HiveField(4)
  bool remind;

  Task({
    required this.id,
    required this.title,
    required this.dateTime,
    this.status = TaskStatus.todo,
    this.remind = true,
  });

  // ---------- Utility helpers ----------

  /// For sorting by time/date
  int compareTo(Task other) {
    return dateTime.compareTo(other.dateTime);
  }

  /// Check overdue status
  bool get isOverdue => dateTime.isBefore(DateTime.now());

  /// Clone task safely (used in edit flows)
  Task copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    TaskStatus? status,
    bool? remind,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      remind: remind ?? this.remind,
    );
  }
}

@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  todo,

  @HiveField(1)
  doing,

  @HiveField(2)
  done,
}
