import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/mock_data.dart';
import '../models/group.dart';
import 'repositories.dart';

/// ログイン中ユーザーのID。Phase 4 で認証から取得するよう差し替える。
final currentUserIdProvider = Provider<String>((ref) => MockData.currentUserId);

/// 所属グループ一覧。
final groupsProvider = Provider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).all(),
);

/// 現在表示中のグループID。タスク一覧の切り替え対象。
class CurrentGroupIdNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(groupsProvider).first.id;

  void select(String groupId) => state = groupId;
}

final currentGroupIdProvider =
    NotifierProvider<CurrentGroupIdNotifier, String>(
  CurrentGroupIdNotifier.new,
);

/// 現在表示中のグループ本体。
final currentGroupProvider = Provider<Group>((ref) {
  final id = ref.watch(currentGroupIdProvider);
  final groups = ref.watch(groupsProvider);
  return groups.firstWhere((g) => g.id == id, orElse: () => groups.first);
});

/// グループ内のユーザー表示名を引く。自分は「自分」と表示する。
String memberNameOf(
  List<Group> groups,
  String groupId,
  String userId, {
  String currentUserId = 'me',
}) {
  if (userId == currentUserId) return '自分';
  final group = groups.where((g) => g.id == groupId);
  if (group.isEmpty) return '不明';
  final member = group.first.members.where((m) => m.id == userId);
  return member.isEmpty ? '不明' : member.first.displayName;
}
