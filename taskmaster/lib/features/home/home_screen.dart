import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../tasks/task_model.dart';
import '../tasks/add_task_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> _titles = ["TODO", "DOING", "DONE"];

  Box<Task> get box => Hive.box<Task>('tasks');

  /// SORTED tasks
  List<Task> _tasksByStatus(TaskStatus status) {
    final list = box.values
        .where((t) => t.status == status)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return list;
  }

  /// ADD
  void _addTask(String title, DateTime time, bool remind) async {
    final task = Task(
      id: Random().nextInt(999999).toString(),
      title: title,
      dateTime: time,
      remind: remind,
    );

    box.put(task.id, task);

    if (remind) {
      await NotificationService.schedule(
        task.id.hashCode,
        task.title,
        time,
      );
    }

    setState(() {});
  }

  /// MOVE FORWARD
  void _moveForward(Task task) {
    if (task.status == TaskStatus.todo) {
      task.status = TaskStatus.doing;
    } else if (task.status == TaskStatus.doing) {
      task.status = TaskStatus.done;
    }
    task.save();
    setState(() {});
  }

  /// MOVE BACKWARD (only middle page)
  void _moveBackward(Task task) {
    if (task.status == TaskStatus.doing) {
      task.status = TaskStatus.todo;
      task.save();
      setState(() {});
    }
  }

  /// DELETE (only todo + done)
  void _deleteTask(Task task) {
    NotificationService.cancel(task.id.hashCode);
    task.delete();
    setState(() {});
  }

  /// EDIT
  void _editTask(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(editTask: task),
      ),
    );

    if (result != null) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TaskMaster - ${_titles[_currentIndex]}"),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: [
          _buildPage(TaskStatus.todo),
          _buildPage(TaskStatus.doing),
          _buildPage(TaskStatus.done),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          _pageController.jumpToPage(i);
          setState(() => _currentIndex = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Todo"),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: "Doing"),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: "Done"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );

          if (result != null) {
            _addTask(result['title'], result['time'], result['remind']);
          }
        },
      ),
    );
  }

  Widget _buildPage(TaskStatus status) {
    final tasks = _tasksByStatus(status);

    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        return Dismissible(
          key: ValueKey(task.id),

          /// swipe rules
          confirmDismiss: (direction) async {
            if (status == TaskStatus.todo &&
                direction == DismissDirection.endToStart) {
              _deleteTask(task);
              return true;
            }

            if (status == TaskStatus.done &&
                direction == DismissDirection.endToStart) {
              _deleteTask(task);
              return true;
            }

            if (status == TaskStatus.doing) {
              if (direction == DismissDirection.startToEnd) {
                _moveForward(task);
              } else {
                _moveBackward(task);
              }
              return true;
            }

            if (direction == DismissDirection.startToEnd) {
              _moveForward(task);
              return true;
            }

            return false;
          },

          background: _swipeBg(Icons.arrow_forward, Colors.green, true),
          secondaryBackground:
              _swipeBg(Icons.delete, Colors.red, false),

          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${task.dateTime.day}/${task.dateTime.month}/${task.dateTime.year} "
                "${task.dateTime.hour.toString().padLeft(2, '0')}:"
                "${task.dateTime.minute.toString().padLeft(2, '0')}",
              ),
              leading: CircleAvatar(
                backgroundColor: status == TaskStatus.todo
                    ? Colors.orange
                    : status == TaskStatus.doing
                        ? Colors.blue
                        : Colors.green,
                child: const Icon(Icons.task, color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editTask(task),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _swipeBg(IconData icon, Color color, bool left) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(left: left ? 20 : 0, right: left ? 0 : 20),
      child: Icon(icon, color: Colors.white),
    );
  }
}
