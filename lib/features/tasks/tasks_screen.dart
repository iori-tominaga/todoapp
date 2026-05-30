import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group.dart';
import '../../models/task.dart';
import '../../providers/group_providers.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_tokens.dart';
import 'widgets/status_change_dialog.dart';
import 'widgets/task_tile.dart';

/// ③ タスク一覧（メイン画面）。
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  Future<void> _openGroupPicker(BuildContext context, WidgetRef ref) async {
    final groups = ref.read(groupsProvider);
    final currentId = ref.read(currentGroupIdProvider);
    final selected = await showModalBottomSheet<Group>(
      context: context,
      builder: (context) =>
          _GroupPickerSheet(groups: groups, selectedId: currentId),
    );
    if (selected != null) {
      ref.read(currentGroupIdProvider.notifier).select(selected.id);
    }
  }

  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, Task task) async {
    final next = await showStatusChangeDialog(
      context,
      taskTitle: task.title,
      current: task.status,
    );
    if (next == null || next == task.status) return;
    ref.read(tasksProvider.notifier).changeStatus(task.id, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final group = ref.watch(currentGroupProvider);
    final tasks = ref.watch(currentGroupTasksProvider);
    final groups = ref.watch(groupsProvider);
    final me = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _openGroupPicker(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(group.name),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/groups/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/tasks/add'),
          ),
          SizedBox(width: t.spaceXs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/add'),
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(t.spaceMd, t.spaceSm, t.spaceMd, t.spaceXl),
              itemCount: tasks.length + 1,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, i) {
                if (i == tasks.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: t.spaceMd),
                    child: Text(
                      '並び順: 日付 → 時間あり優先 → 時間 → 優先度 → 作成順',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                }
                final task = tasks[i];
                return TaskTile(
                  task: task,
                  creatorName:
                      memberNameOf(groups, group.id, task.createdBy, currentUserId: me),
                  completerName: task.completedBy == null
                      ? null
                      : memberNameOf(groups, group.id, task.completedBy!,
                          currentUserId: me),
                  onStatusTap: () => _changeStatus(context, ref, task),
                );
              },
            ),
          ),
          if (!group.isPremium) const _AdBanner(),
        ],
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: EdgeInsets.all(t.spaceMd),
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusSm),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        '広告バナー（無料グループのみ表示）',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _GroupPickerSheet extends StatelessWidget {
  const _GroupPickerSheet({required this.groups, required this.selectedId});

  final List<Group> groups;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(t.spaceMd),
            child: Text('グループを切り替え',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final g in groups)
            ListTile(
              title: Text(g.name),
              subtitle: Text(
                  '👤${g.memberCount}${g.isPremium ? ' ・ ★プレミアム' : ''}'),
              trailing: g.id == selectedId
                  ? Icon(Icons.check, color: t.seed)
                  : null,
              onTap: () => Navigator.of(context).pop(g),
            ),
          SizedBox(height: t.spaceSm),
        ],
      ),
    );
  }
}
