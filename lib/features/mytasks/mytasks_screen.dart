import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../providers/group_providers.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_tokens.dart';
import '../../util/date_format.dart';

/// ⑤ Myタスク（自分が作成したタスクのみ・差し戻し・リマインド送信）。
class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final groups = ref.watch(groupsProvider);
    final items = [
      for (final task in ref.watch(myTasksProvider))
        _MyTaskItem(
          groupName: groups
              .firstWhere((g) => g.id == task.groupId,
                  orElse: () => groups.first)
              .name,
          task: task,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Myタスク')),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Text('自分が作成したタスクのみ表示',
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: t.spaceMd),
          for (final item in items) ...[
            _MyTaskCard(item: item),
            SizedBox(height: t.spaceMd),
          ],
        ],
      ),
    );
  }
}

class _MyTaskItem {
  const _MyTaskItem({required this.groupName, required this.task});
  final String groupName;
  final Task task;
}

class _MyTaskCard extends StatelessWidget {
  const _MyTaskCard({required this.item});
  final _MyTaskItem item;

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final task = item.task;
    final isDone = task.status == TaskStatus.done;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(t.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(
                    label: task.status.shortLabel,
                    color: task.status.color(context)),
                SizedBox(width: t.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: t.spaceXs),
                      Text(
                        '${item.groupName} / ${formatDueDate(task.dueDate)}'
                        '${isDone ? ' ・ 完了' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spaceSm),
            if (isDone)
              OutlinedButton.icon(
                onPressed: () => _snack(context, '「完了」を着手中へ差し戻しました'),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('差し戻し'),
              )
            else
              OutlinedButton.icon(
                onPressed: () =>
                    _snack(context, 'グループ全員にリマインドを送りました（ミュート除く）'),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text('リマインド送信'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(t.radiusSm),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
