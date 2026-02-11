import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'task_model.dart';
import '../../services/notification_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
 State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _controller;
  late DateTime _dateTime;
  late bool _remind;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _dateTime = widget.task.dateTime;
    _remind = widget.task.remind;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );

    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;

    widget.task.title = _controller.text.trim();
    widget.task.dateTime = _dateTime;
    widget.task.remind = _remind;

    await widget.task.save();

    // 🔔 reschedule notification
    await NotificationService.cancel(widget.task.id.hashCode);

    if (_remind) {
      await NotificationService.schedule(
        widget.task.id.hashCode,
        widget.task.title,
        _dateTime,
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Task")),
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
                    "${_dateTime.day}/${_dateTime.month}/${_dateTime.year} "
                    "${_dateTime.hour.toString().padLeft(2, '0')}:"
                    "${_dateTime.minute.toString().padLeft(2, '0')}",
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDateTime,
                  child: const Text("Change"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text("Reminder"),
              value: _remind,
              onChanged: (v) => setState(() => _remind = v),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Update Task"),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
