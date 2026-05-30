import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_stats.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'group_providers.dart';
import 'task_providers.dart';

/// 現在表示中グループの統計。完了タスクの履歴から実際に集計する。
///
/// Phase 2 まではモック値（`MockData.familyStats`）を直返ししていたが、
/// Phase 3 で [tasksProvider] のタスク履歴を元に算出するよう差し替えた。
/// タスクを完了するたびに各指標が自動で再計算される。
final statsProvider = Provider<GroupStats>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  final groups = ref.watch(groupsProvider);
  final me = ref.watch(currentUserIdProvider);

  final done = ref
      .watch(tasksProvider)
      .where((t) =>
          t.groupId == groupId &&
          t.status == TaskStatus.done &&
          t.completedAt != null &&
          t.completedBy != null)
      .toList();

  if (done.isEmpty) {
    return const GroupStats(
      onTimeRate: 0,
      avgCompletionDays: 0,
      completionRanking: [],
      speedRanking: [],
      weeklyCompleted: [0, 0, 0, 0, 0, 0, 0],
    );
  }

  // 期限内完了率: 完了日が期限日以前なら「期限内」とみなす。
  final onTime = done
      .where((t) => !_dateOnly(t.completedAt!).isAfter(_dateOnly(t.dueDate)))
      .length;
  final onTimeRate = onTime / done.length;

  // 平均消化時間（作成 → 完了 の日数）。
  final avgDays =
      done.map(_completionDays).reduce((a, b) => a + b) / done.length;

  // メンバー別の消化数と所要日数を集計。
  final countByMember = <String, int>{};
  final daysByMember = <String, List<double>>{};
  for (final t in done) {
    final by = t.completedBy!;
    countByMember.update(by, (v) => v + 1, ifAbsent: () => 1);
    daysByMember.putIfAbsent(by, () => []).add(_completionDays(t));
  }

  String nameOf(String id) =>
      memberNameOf(groups, groupId, id, currentUserId: me);

  // 消化数ランキング（多い順）。
  final completionRanking = countByMember.entries
      .map((e) => RankingEntry(
            memberName: nameOf(e.key),
            value: e.value.toDouble(),
            isMe: e.key == me,
          ))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // 消化スピードランキング（平均日数が小さい順 ＝ 速い順）。
  final speedRanking = daysByMember.entries
      .map((e) => RankingEntry(
            memberName: nameOf(e.key),
            value: _round1(e.value.reduce((a, b) => a + b) / e.value.length),
            isMe: e.key == me,
          ))
      .toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  // 直近7日(月〜日)の消化数推移。画面ラベルに合わせ 2026-06-01(月) 起点。
  // Phase 4 で実データ接続時に「今日起点の直近7日」へ作り替える。
  final weekStart = DateTime(2026, 6, 1);
  final weeklyCompleted = [
    for (var i = 0; i < 7; i++)
      done
          .where((t) =>
              _sameDate(t.completedAt!, weekStart.add(Duration(days: i))))
          .length,
  ];

  return GroupStats(
    onTimeRate: onTimeRate,
    avgCompletionDays: _round1(avgDays),
    completionRanking: completionRanking,
    speedRanking: speedRanking,
    weeklyCompleted: weeklyCompleted,
  );
});

double _completionDays(Task t) =>
    t.completedAt!.difference(t.createdAt).inMinutes / 1440.0;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

double _round1(double v) => (v * 10).round() / 10;
