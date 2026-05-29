/// ランキング1行（メンバー別の集計値）。
class RankingEntry {
  const RankingEntry({
    required this.memberName,
    required this.value,
    this.isMe = false,
  });

  final String memberName;
  final double value;
  final bool isMe;
}

/// グループの統計サマリ。
class GroupStats {
  const GroupStats({
    required this.onTimeRate,
    required this.avgCompletionDays,
    required this.completionRanking,
    required this.speedRanking,
    required this.weeklyCompleted,
  });

  /// 期限内完了率（0-1）。
  final double onTimeRate;

  /// 平均消化時間（日）。
  final double avgCompletionDays;

  /// 消化数ランキング（多い順）。
  final List<RankingEntry> completionRanking;

  /// 消化スピードランキング（速い順・値は日数）。
  final List<RankingEntry> speedRanking;

  /// 直近の消化数推移（折れ線用）。
  final List<int> weeklyCompleted;
}
