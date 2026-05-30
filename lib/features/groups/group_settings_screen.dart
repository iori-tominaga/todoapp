import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/group_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/premium_card.dart';
import 'widgets/invite_link_dialog.dart';

/// ⑧ グループ設定（招待リンク・メンバー管理・プレミアム案内）。
class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({super.key});

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmLeave(BuildContext context, String groupName) async {
    final ok = await showConfirmDialog(
      context,
      title: 'グループを退出 / 削除',
      message: '「$groupName」から退出しますか？\nオーナーの場合はグループが削除され、元に戻せません。',
      confirmLabel: '退出 / 削除',
      destructive: true,
    );
    if (ok && context.mounted) {
      _snack(context, 'グループを退出しました');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;
    final group = ref.watch(currentGroupProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('グループ設定'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Text('グループ名', style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceXs),
          TextField(
            controller: TextEditingController(text: group.name),
            decoration: const InputDecoration(),
          ),
          SizedBox(height: t.spaceLg),

          Text('メンバー（${group.memberCount} / ${group.memberLimit}）',
              style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceSm),
          Card(
            child: Column(
              children: [
                for (final m in group.members)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: t.seed.withValues(alpha: 0.15),
                      child: Text(m.initial,
                          style: TextStyle(color: t.seed, fontSize: 12)),
                    ),
                    title: Text(m.displayName),
                    trailing: m.isOwner
                        ? Text('オーナー',
                            style: Theme.of(context).textTheme.labelSmall)
                        : null,
                  ),
              ],
            ),
          ),
          SizedBox(height: t.spaceMd),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  showInviteLinkDialog(context, groupName: group.name),
              icon: const Icon(Icons.link),
              label: const Text('招待リンクを発行・共有'),
            ),
          ),
          SizedBox(height: t.spaceLg),

          const PremiumCard(subtitle: '¥600 / 月 ・ グループ全員に適用'),
          SizedBox(height: t.spaceLg),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmLeave(context, group.name),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.priorityHigh,
                side: BorderSide(color: t.priorityHigh),
              ),
              child: const Text('グループを退出 / 削除'),
            ),
          ),
          SizedBox(height: t.spaceMd),
          Center(
            child: Text('オーナー: ${group.owner.displayName}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
