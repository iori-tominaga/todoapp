import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/character_state.dart';
import 'task_providers.dart';

/// キャラクターの状態。
///
/// 体調は [totalPendingLoadProvider]（全グループの未完了タスク総数）から
/// 自動算出される。タスクを完了にすると体調が連動して回復する。
/// 攻撃/防御は装備実装（Phase 7）までの暫定固定値。
final characterProvider = Provider<CharacterState>((ref) {
  final pendingLoad = ref.watch(totalPendingLoadProvider);
  return CharacterState(pendingLoad: pendingLoad, attack: 12, defense: 8);
});
