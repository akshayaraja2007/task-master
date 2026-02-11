import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'task_model.dart';
import '../../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? editTask;

  const AddTaskScreen({super.key, this.editTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _controller = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  bool _remind = true;

  bool get _isEditing => widget.editTask != null;

  @override
  void initState() {
    super.initState();

    /// preload when editing
    if (_isEditing) {
      final task = widget.editTask!;
      _controller.text = task.title;
      _selectedDateTime = task.dateTime;
      _remind = task.remind;
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final box = Hive.box<Task>('tasks');

    /// EDIT MODE
    if (_isEditing) {
      final task = widget.editTask!;

      /// cancel old notification
      await NotificationService.cancel(task.id.hashCode);

      task.title = title;
      task.dateTime = _selectedDateTime;
      task.remind = _remind;

      await task.save();

      /// reschedule
      if (_remind) {
        await NotificationService.schedule(
          task.id.hashCode,
          task.title,
          _selectedDateTime,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    /// ADD MODE
    Navigator.pop(context, {
      'title': title,
      'time': _selectedDateTime,
      'remind': _remind,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Task" : "Add Task"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Task title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    "Date & Time:\n"
                    "${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} "
                    "${_selectedDateTime.hour.toString().padLeft(2, '0')}:"
                    "${_selectedDateTime.minute.toString().padLeft(2, '0')}",
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDateTime,
                  child: const Text("Pick"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text("Enable reminder"),
              value: _remind,
              onChanged: (v) => setState(() => _remind = v),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? "Update Task" : "Save Task"),
                onPressed: _saveTask,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
