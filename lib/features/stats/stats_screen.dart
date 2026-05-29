import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('統計')),
      body: const Center(child: Text('統計・ランキング（Phase 1 で実装）')),
    );
  }
}
