import 'package:flutter/material.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('キャラクター')),
      body: const Center(child: Text('キャラクター（Phase 1 で実装）')),
    );
  }
}
