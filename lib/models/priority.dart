import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// タスクの優先度（高 / 中 / 低）。
enum Priority {
  high,
  mid,
  low;

  /// ソート用の序列（高=0 が最優先）。
  int get rank => switch (this) {
        Priority.high => 0,
        Priority.mid => 1,
        Priority.low => 2,
      };

  String get label => switch (this) {
        Priority.high => '高',
        Priority.mid => '中',
        Priority.low => '低',
      };

  /// 現在のデザイントークンから優先度カラーを引く。
  Color color(BuildContext context) {
    final t = context.tokens;
    return switch (this) {
      Priority.high => t.priorityHigh,
      Priority.mid => t.priorityMid,
      Priority.low => t.priorityLow,
    };
  }
}
