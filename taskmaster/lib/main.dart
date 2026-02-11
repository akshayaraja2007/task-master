import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/tasks/task_model.dart';
import 'features/home/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------- Hive init ----------
  await Hive.initFlutter();

  // Register adapters safely (prevents duplicate crash)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TaskStatusAdapter());
  }

  // Open storage box
  await Hive.openBox<Task>('tasks');

  // ---------- Notifications ----------
  await NotificationService.init();

  // ---------- Run app ----------
  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMaster',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.system,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),

      home: const HomeScreen(),
    );
  }
}
