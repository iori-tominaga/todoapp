import 'package:flutter/material.dart';

import '../../../models/task.dart';
import '../../../theme/app_tokens.dart';
import '../../../util/date_format.dart';

/// タスク一覧の1行（ステータスチップ＋タイトル/期限＋優先度ドット）。
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.creatorName,
    required this.onStatusTap,
  });

  final Task task;
  final String creatorName;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final statusColor = task.status.color(context);
    final priorityColor = task.priority.color(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(
            label: task.status.shortLabel,
            color: statusColor,
            onTap: onStatusTap,
          ),
          SizedBox(width: t.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: t.spaceXs),
                Text(
                  taskSubtitle(task, creatorName),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(width: t.spaceSm),
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusSm),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(t.radiusSm),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
