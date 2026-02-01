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
