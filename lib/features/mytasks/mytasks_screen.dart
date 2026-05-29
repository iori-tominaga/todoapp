import 'package:flutter/material.dart';

class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Myタスク')),
      body: const Center(child: Text('自分が作成したタスク（Phase 1 で実装）')),
    );
  }
}
