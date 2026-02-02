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

  List<Task> _tasksByStatus(TaskStatus status) {
    return box.values.where((t) => t.status == status).toList();
  }

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

  void _moveForward(Task task) {
    if (task.status == TaskStatus.todo) {
      task.status = TaskStatus.doing;
    } else if (task.status == TaskStatus.doing) {
      task.status = TaskStatus.done;
    }
    task.save();
    setState(() {});
  }

  void _deleteTask(Task task) {
    NotificationService.cancel(task.id.hashCode);
    task.delete();
    setState(() {});
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
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.arrow_forward, color: Colors.white),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              _moveForward(task);
            } else {
              _deleteTask(task);
            }
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
            ),
          ),
        );
      },
    );
  }
}
