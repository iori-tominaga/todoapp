import 'dart:async';

import '../mock/mock_data.dart';
import '../models/group.dart';
import '../models/member.dart';

/// グループの読み書きを抽象化する。
///
/// Firestore 実装では [watchAll] が所属グループの `snapshots()` に対応する。
abstract class GroupRepository {
  /// 所属グループをリアルタイムに流す。
  Stream<List<Group>> watchAll();

  /// 新規グループを作成し、自分をオーナーとして登録する。作成したグループIDを返す。
  Future<String> createGroup({required String name, required String displayName});

  /// 招待リンク用のコードを発行し、`code → groupId` を引けるようにする。発行コードを返す。
  Future<String> createInvite(String groupId);

  /// 招待コードから所属先グループIDを引く。無効なら null。
  Future<String?> resolveInvite(String code);

  /// 招待経由で自分をグループに追加する（自己参加）。
  Future<void> joinGroup({required String groupId, required String displayName});
}

/// [MockData] をシードにしたインメモリ実装。
///
/// 実 Firebase に切り替えた今はロールバック用。作成/参加で再 emit する。
class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository() : _groups = List<Group>.from(MockData.groups);

  final List<Group> _groups;
  final Map<String, String> _invites = {};
  final StreamController<List<Group>> _controller =
      StreamController<List<Group>>.broadcast();
  int _seq = 0;

  @override
  Stream<List<Group>> watchAll() async* {
    yield List.unmodifiable(_groups);
    yield* _controller.stream;
  }

  @override
  Future<String> createGroup(
      {required String name, required String displayName}) async {
    final id = 'g_local_${_seq++}';
    _groups.add(Group(
      id: id,
      name: name,
      members: [
        Member(id: MockData.currentUserId, displayName: displayName, isOwner: true),
      ],
    ));
    _emit();
    return id;
  }

  @override
  Future<String> createInvite(String groupId) async {
    final code = 'inv${_seq++}';
    _invites[code] = groupId;
    return code;
  }

  @override
  Future<String?> resolveInvite(String code) async => _invites[code];

  @override
  Future<void> joinGroup(
      {required String groupId, required String displayName}) async {
    final i = _groups.indexWhere((g) => g.id == groupId);
    if (i < 0) return;
    final g = _groups[i];
    if (g.members.any((m) => m.id == MockData.currentUserId)) return;
    _groups[i] = Group(
      id: g.id,
      name: g.name,
      members: [
        ...g.members,
        Member(id: MockData.currentUserId, displayName: displayName),
      ],
      isPremium: g.isPremium,
      memberLimit: g.memberLimit,
      notificationsEnabled: g.notificationsEnabled,
    );
    _emit();
  }

  void dispose() => _controller.close();

  void _emit() => _controller.add(List.unmodifiable(_groups));
}
