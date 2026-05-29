import 'package:flutter/material.dart';

import '../../../models/task_status.dart';
import '../../../theme/app_tokens.dart';

/// ステータス変更の確認ダイアログ（仕様 4.1 / 誤タップ防止）。
///
/// ラジオで新ステータスを選び [更新] で確定。
/// 「グループ全員に通知が送られます」の注意書き付き。
/// 確定時は選んだ [TaskStatus] を、キャンセル時は null を返す。
Future<TaskStatus?> showStatusChangeDialog(
  BuildContext context, {
  required String taskTitle,
  required TaskStatus current,
}) {
  return showDialog<TaskStatus>(
    context: context,
    builder: (context) => _StatusChangeDialog(taskTitle: taskTitle, current: current),
  );
}

class _StatusChangeDialog extends StatefulWidget {
  const _StatusChangeDialog({required this.taskTitle, required this.current});

  final String taskTitle;
  final TaskStatus current;

  @override
  State<_StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<_StatusChangeDialog> {
  late TaskStatus _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('ステータスを変更'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '「${widget.taskTitle}」',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: t.spaceSm),
          RadioGroup<TaskStatus>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in TaskStatus.values)
                  RadioListTile<TaskStatus>(
                    value: s,
                    title: Text(s.label),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
          SizedBox(height: t.spaceSm),
          Container(
            padding: EdgeInsets.all(t.spaceSm),
            decoration: BoxDecoration(
              color: t.priorityHigh.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(t.radiusSm),
              border: Border.all(color: t.priorityHigh.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 16, color: t.priorityHigh),
                SizedBox(width: t.spaceXs),
                Expanded(
                  child: Text(
                    '変更するとグループ全員に通知が送られます（ミュート中の人を除く）',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: t.priorityHigh),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('更新'),
        ),
      ],
      backgroundColor: cs.surface,
    );
  }
}
