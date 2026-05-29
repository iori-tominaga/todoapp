import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/premium_card.dart';

/// ⑨ 設定 / 課金（アカウント・プレミアム・グループ別通知ミュート）。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Map<String, bool> _notify = {
    for (final g in MockData.groups) g.id: g.notificationsEnabled,
  };
  bool _dueReminder = true;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'ログアウト',
      message: '匿名アカウントのままログアウトすると、データを復元できなくなる場合があります。ログアウトしますか？',
      confirmLabel: 'ログアウト',
      destructive: true,
    );
    if (ok && context.mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          _SectionLabel('アカウント'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('プロフィール編集'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('アカウント登録（匿名 → 正式）'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/account/register'),
                ),
              ],
            ),
          ),
          SizedBox(height: t.spaceLg),

          const PremiumCard(subtitle: '¥600 / 月 ・ 広告除去 ＋ 上級機能'),
          SizedBox(height: t.spaceLg),

          _SectionLabel('通知設定（グループ別ミュート）'),
          Card(
            child: Column(
              children: [
                for (final g in MockData.groups)
                  SwitchListTile(
                    title: Text(g.name),
                    value: _notify[g.id]!,
                    onChanged: (v) => setState(() => _notify[g.id] = v),
                  ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('期限リマインド'),
                  value: _dueReminder,
                  onChanged: (v) => setState(() => _dueReminder = v),
                ),
              ],
            ),
          ),
          SizedBox(height: t.spaceLg),

          TextButton(
            onPressed: () => context.push('/legal'),
            child: const Text('利用規約 / プライバシー'),
          ),
          TextButton(
            onPressed: () => _confirmLogout(context),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spaceSm, left: t.spaceXs),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
