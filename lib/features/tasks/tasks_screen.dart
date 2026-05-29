import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../models/group.dart';
import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../theme/app_tokens.dart';
import 'widgets/status_change_dialog.dart';
import 'widgets/task_tile.dart';

/// ③ タスク一覧（メイン画面）。
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Group _group = MockData.groups.first;
  late List<Task> _tasks = _loadTasks(_group.id);

  List<Task> _loadTasks(String groupId) {
    final list = List<Task>.from(MockData.tasksByGroup[groupId] ?? const []);
    list.sort(compareTasks);
    return list;
  }

  void _switchGroup(Group g) {
    setState(() {
      _group = g;
      _tasks = _loadTasks(g.id);
    });
  }

  Future<void> _openGroupPicker() async {
    final selected = await showModalBottomSheet<Group>(
      context: context,
      builder: (context) => _GroupPickerSheet(
        groups: MockData.groups,
        selectedId: _group.id,
      ),
    );
    if (selected != null) _switchGroup(selected);
  }

  Future<void> _changeStatus(Task task) async {
    final next = await showStatusChangeDialog(
      context,
      taskTitle: task.title,
      current: task.status,
    );
    if (next == null || next == task.status) return;
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i >= 0) {
        _tasks[i] = _tasks[i].copyWith(
          status: next,
          completedBy: next == TaskStatus.done ? MockData.currentUserId : null,
        );
        _tasks.sort(compareTasks);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _openGroupPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_group.name),
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
              itemCount: _tasks.length + 1,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, i) {
                if (i == _tasks.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: t.spaceMd),
                    child: Text(
                      '並び順: 日付 → 時間あり優先 → 時間 → 優先度 → 作成順',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                }
                final task = _tasks[i];
                return TaskTile(
                  task: task,
                  creatorName: MockData.memberName(_group.id, task.createdBy),
                  onStatusTap: () => _changeStatus(task),
                );
              },
            ),
          ),
          if (!_group.isPremium) const _AdBanner(),
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
