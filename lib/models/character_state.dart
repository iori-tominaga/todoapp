/// 体調の段階（見た目の差し替え用）。
enum ConditionStage {
  healthy,
  tired,
  sick;

  String get label => switch (this) {
        ConditionStage.healthy => '元気いっぱい！',
        ConditionStage.tired => 'すこし疲れぎみ',
        ConditionStage.sick => '不調ぎみ…',
      };

  /// プレースホルダの表情（後でアートに差し替える）。
  String get face => switch (this) {
        ConditionStage.healthy => '😊',
        ConditionStage.tired => '😪',
        ConditionStage.sick => '😣',
      };
}

/// キャラクターの状態（ユーザー個人単位）。
///
/// condition は所属する全グループの未完了タスク総数から算出する。
class CharacterState {
  const CharacterState({
    required this.pendingLoad,
    required this.attack,
    required this.defense,
  });

  /// 全グループの未完了タスク総数。
  final int pendingLoad;
  final int attack;
  final int defense;

  /// 体調 0-100。k は暫定係数（将来 Remote Config）。
  int get condition {
    const k = 4;
    final v = 100 - pendingLoad * k;
    return v.clamp(0, 100);
  }

  ConditionStage get stage {
    final c = condition;
    if (c >= 70) return ConditionStage.healthy;
    if (c >= 40) return ConditionStage.tired;
    return ConditionStage.sick;
  }
}
