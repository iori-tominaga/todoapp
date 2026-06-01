import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/priority.dart';
import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../providers/group_providers.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_tokens.dart';

/// ④ タスク追加 / 編集。
///
/// 必須: タイトル・期限(日付)・優先度。時間と担当者は任意。
/// 保存で現在のグループに Firestore 書き込みする。
class TaskEditScreen extends ConsumerStatefulWidget {
  const TaskEditScreen({super.key});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _titleController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  TimeOfDay? _dueTime;
  Priority _priority = Priority.high;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final groupId = ref.read(currentGroupIdProvider);
    final me = ref.read(currentUserIdProvider);
    final dueTime = _dueTime == null
        ? null
        : '${_dueTime!.hour.toString().padLeft(2, '0')}:'
            '${_dueTime!.minute.toString().padLeft(2, '0')}';

    final task = Task(
      id: '',
      title: title,
      dueDate: DateTime(_dueDate.year, _dueDate.month, _dueDate.day),
      hasTime: _dueTime != null,
      dueTime: dueTime,
      priority: _priority,
      status: TaskStatus.notStarted,
      createdBy: me,
      // 番兵: 0 だと _taskToMap が serverTimestamp に置き換える。
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      groupId: groupId,
    );

    try {
      await ref.read(tasksProvider.notifier).add(task);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('タスクを追加'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          _Label('タイトル', required: true),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: '例）牛乳を買う'),
          ),
          SizedBox(height: t.spaceLg),

          _Label('期限・日付', required: true),
          _PickerField(
            value: '${_dueDate.year} / '
                '${_dueDate.month.toString().padLeft(2, '0')} / '
                '${_dueDate.day.toString().padLeft(2, '0')}',
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          SizedBox(height: t.spaceLg),

          _Label('時間（任意）'),
          _PickerField(
            value: _dueTime == null
                ? '未設定'
                : '${_dueTime!.hour.toString().padLeft(2, '0')} : '
                    '${_dueTime!.minute.toString().padLeft(2, '0')}',
            icon: Icons.schedule_outlined,
            onTap: _pickTime,
            onClear: _dueTime == null ? null : () => setState(() => _dueTime = null),
          ),
          SizedBox(height: t.spaceLg),

          _Label('優先度', required: true),
          _PrioritySegment(
            selected: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),
          SizedBox(height: t.spaceLg),

          _Label('担当者'),
          _PickerField(
            value: '未設定',
            icon: Icons.lock_outline,
            trailingText: 'プレミアム',
            onTap: null,
          ),
          SizedBox(height: t.spaceXl),

          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spaceXs),
      child: Row(
        children: [
          Text(text, style: Theme.of(context).textTheme.labelMedium),
          if (required)
            Text(' ＊', style: TextStyle(color: t.priorityHigh)),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.icon,
    this.onTap,
    this.onClear,
    this.trailingText,
  });

  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusSm),
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: t.spaceMd),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusSm),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
              ),
            if (trailingText != null)
              Text(trailingText!,
                  style: Theme.of(context).textTheme.labelSmall),
            SizedBox(width: t.spaceXs),
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PrioritySegment extends StatelessWidget {
  const _PrioritySegment({required this.selected, required this.onChanged});

  final Priority selected;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        for (final p in Priority.values) ...[
          Expanded(
            child: InkWell(
              onTap: () => onChanged(p),
              borderRadius: BorderRadius.circular(t.radiusSm),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(t.radiusSm),
                  border: Border.all(
                    color: selected == p
                        ? p.color(context)
                        : Theme.of(context).colorScheme.outline,
                    width: selected == p ? 2 : 1,
                  ),
                  color: selected == p
                      ? p.color(context).withValues(alpha: 0.12)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: p.color(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: t.spaceXs),
                    Text(p.label),
                  ],
                ),
              ),
            ),
          ),
          if (p != Priority.values.last) SizedBox(width: t.spaceSm),
        ],
      ],
    );
  }
}
