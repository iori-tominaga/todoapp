import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group.dart';
import '../models/member.dart';
import 'auth_providers.dart';
import 'repositories.dart';

/// ログイン中ユーザーのID。認証状態から取得し、未ログイン時は空文字。
final currentUserIdProvider = Provider<String>(
  (ref) => ref.watch(authStateProvider).value ?? '',
);

/// 無料プランで所属できるグループ数の上限。
///
/// サーバ側（Firestoreルール）では「所属グループ数」を数えられないため、
/// この上限はクライアント側でのみ強制する（[canCreateGroupProvider]）。
const int kFreeGroupLimit = 3;

/// 所属グループのストリーム源（非同期）。画面には直接見せない。
final _groupsStreamProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchAll(),
);

/// 所属グループ一覧（同期スナップショット・ロード前は空リスト）。
final groupsProvider = Provider<List<Group>>(
  (ref) => ref.watch(_groupsStreamProvider).value ?? const <Group>[],
);

/// 新しいグループを作成できるか（無料上限の未達）。
final canCreateGroupProvider = Provider<bool>(
  (ref) => ref.watch(groupsProvider).length < kFreeGroupLimit,
);

/// 現在表示中のグループID。タスク一覧の切り替え対象。
class CurrentGroupIdNotifier extends Notifier<String> {
  @override
  String build() {
    final groups = ref.watch(groupsProvider);
    return groups.isEmpty ? '' : groups.first.id;
  }

  void select(String groupId) => state = groupId;
}

final currentGroupIdProvider =
    NotifierProvider<CurrentGroupIdNotifier, String>(
  CurrentGroupIdNotifier.new,
);

/// グループ未ロード時のフォールバック（描画を落とさないための空グループ）。
const _emptyGroup = Group(id: '', name: '', members: <Member>[]);

/// 現在表示中のグループ本体。
final currentGroupProvider = Provider<Group>((ref) {
  final id = ref.watch(currentGroupIdProvider);
  final groups = ref.watch(groupsProvider);
  if (groups.isEmpty) return _emptyGroup;
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
