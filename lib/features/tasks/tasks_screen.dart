import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家族 ▼')),
      body: const Center(child: Text('タスク一覧（Phase 1 で実装）')),
    );
  }
}
