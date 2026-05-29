import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';

/// グループ新規作成。
///
/// グループ名を入力して [作成] で確定（モック）。
/// 無料プランの上限（3グループ / 6人）の注意書き付き。
class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _create() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('「$name」を作成しました')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('グループを作成'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Text('グループ名', style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceXs),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
            decoration: const InputDecoration(
              hintText: '例）家族 / 開発チーム',
            ),
          ),
          SizedBox(height: t.spaceSm),
          Text(
            '作成後に招待リンクでメンバーを追加できます。\n無料プランは 3グループ / 6人まで。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: t.spaceLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _create,
              child: const Text('作成'),
            ),
          ),
        ],
      ),
    );
  }
}
