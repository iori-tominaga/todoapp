import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_tokens.dart';

/// ② グループ一覧 / 切替。
class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('マイグループ'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          for (final g in MockData.groups) ...[
            Card(
              child: ListTile(
                title: Text(g.name,
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(
                    '👤${g.memberCount}${g.isPremium ? ' ・ ★プレミアム' : ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/tasks'),
              ),
            ),
            SizedBox(height: t.spaceSm),
          ],
          SizedBox(height: t.spaceSm),
          OutlinedButton.icon(
            onPressed: () => context.push('/groups/create'),
            icon: const Icon(Icons.add),
            label: const Text('新規グループ作成'),
          ),
          SizedBox(height: t.spaceSm),
          Center(
            child: Text('無料は 3グループ / 6人まで',
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}
