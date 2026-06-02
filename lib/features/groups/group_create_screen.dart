import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/repositories.dart';
import '../../theme/app_tokens.dart';

/// グループ新規作成。
///
/// グループ名と自分の表示名を入力して [作成] で確定し、Firestore に書き込む。
/// 作成後はそのグループを選択してタスク画面へ。
class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final _nameController = TextEditingController();
  late final _displayNameController =
      TextEditingController(text: ref.read(currentDisplayNameProvider) ?? '');
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final displayName = _displayNameController.text.trim();
    if (name.isEmpty || displayName.isEmpty || _submitting) return;
    if (!ref.read(canCreateGroupProvider)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('無料プランは $kFreeGroupLimit グループまでです')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(groupRepositoryProvider)
          .createGroup(name: name, displayName: displayName);
      ref.read(currentGroupIdProvider.notifier).select(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('「$name」を作成しました')));
      context.go('/tasks');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('作成に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canCreate = ref.watch(canCreateGroupProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('グループを作成'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          if (!canCreate) ...[
            Container(
              padding: EdgeInsets.all(t.spaceSm),
              decoration: BoxDecoration(
                color: t.priorityHigh.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(t.radiusSm),
              ),
              child: Text(
                '無料プランは $kFreeGroupLimit グループまでです。\n新しく作るには既存のグループから退出してください。',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: t.priorityHigh),
              ),
            ),
            SizedBox(height: t.spaceMd),
          ],
          Text('グループ名', style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceXs),
          TextField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '例）家族 / 開発チーム',
            ),
          ),
          SizedBox(height: t.spaceLg),
          Text('あなたの表示名', style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceXs),
          TextField(
            controller: _displayNameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
            decoration: const InputDecoration(
              hintText: '例）パパ / いおり',
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
              onPressed: (_submitting || !canCreate) ? null : _create,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('作成'),
            ),
          ),
        ],
      ),
    );
  }
}
