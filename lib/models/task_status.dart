import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// タスクのステータス（未実施 → 着手中 → 完了）。
enum TaskStatus {
  notStarted,
  inProgress,
  done;

  String get label => switch (this) {
        TaskStatus.notStarted => '未実施',
        TaskStatus.inProgress => '着手中',
        TaskStatus.done => '完了',
      };

  /// 一覧のステータスチップに表示する短い1文字ラベル。
  String get shortLabel => switch (this) {
        TaskStatus.notStarted => '未',
        TaskStatus.inProgress => '進',
        TaskStatus.done => '完',
      };

  Color color(BuildContext context) {
    final t = context.tokens;
    return switch (this) {
      TaskStatus.notStarted => t.statusNotStarted,
      TaskStatus.inProgress => t.statusInProgress,
      TaskStatus.done => t.statusDone,
    };
  }
}
