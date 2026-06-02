import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../models/priority.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'auth_repository.dart';
import 'group_repository.dart';
import 'task_repository.dart';

/// === Firestore / FirebaseAuth 実装（Phase 4-接続） ===
///
/// インターフェース（Stream watchAll ＋ Future 書き込み）は Phase 4a で
/// Firestore に合わせて設計済みなので、`snapshots()` がそのまま乗る。
/// データ構造は docs/specs/firebase-setup.md を正とする。

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<Task>> watchForGroups(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value(const <Task>[]);

    // 各グループの tasks サブコレクションを購読し、combineLatest 風にマージする。
    // 最新値をグループ単位で保持し、どれかが更新されるたび連結して emit する。
    final controller = StreamController<List<Task>>();
    final latest = <String, List<Task>>{for (final g in groupIds) g: const []};
    final subs = <String, StreamSubscription>{};
    var closed = false;

    void emit() =>
        controller.add([for (final g in groupIds) ...latest[g] ?? const []]);

    // 参加直後はタスク読み取りルールの get(group) が旧 memberIds を見て
    // 一瞬拒否されることがある。Firestore のリスナーはエラーで切れると
    // 自力で復活しないため、少し待って張り直して伝播後に取りこぼしを拾う。
    void subscribe(String gid) {
      subs[gid] = _db.collection('groups/$gid/tasks').snapshots().listen(
        (snap) {
          latest[gid] = snap.docs.map(_taskFromDoc).toList();
          emit();
        },
        onError: (Object _) async {
          await subs[gid]?.cancel();
          if (closed) return;
          await Future<void>.delayed(const Duration(seconds: 1));
          if (!closed) subscribe(gid);
        },
      );
    }

    for (final gid in groupIds) {
      subscribe(gid);
    }

    controller.onCancel = () async {
      closed = true;
      for (final s in subs.values) {
        await s.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<void> updateStatus(
      String groupId, String taskId, TaskStatus status, String? completedBy) {
    final done = status == TaskStatus.done;
    return _db.doc('groups/$groupId/tasks/$taskId').update({
      'status': status.name,
      'completedBy': done ? completedBy : null,
      'completedAt': done ? FieldValue.serverTimestamp() : null,
    });
  }

  @override
  Future<void> add(Task task) {
    return _db.collection('groups/${task.groupId}/tasks').add(_taskToMap(task));
  }
}

class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository(this._db, this._uid);

  final FirebaseFirestore _db;

  /// 所属判定に使うログイン中ユーザーID。
  final String _uid;

  @override
  Stream<List<Group>> watchAll() {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: _uid)
        .snapshots()
        .map((snap) => snap.docs.map(_groupFromDoc).toList());
  }

  @override
  Future<String> createGroup(
      {required String name, required String displayName}) async {
    final doc = _db.collection('groups').doc();
    await doc.set({
      'name': name,
      'isPremium': false,
      'memberLimit': 6,
      'notificationsEnabled': true,
      'memberIds': [_uid],
      'members': [
        {'id': _uid, 'displayName': displayName, 'isOwner': true},
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  @override
  Future<String> createInvite(String groupId) async {
    final code = _generateInviteCode();
    await _db.collection('invites').doc(code).set({
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  @override
  Future<String?> resolveInvite(String code) async {
    final snap = await _db.collection('invites').doc(code).get();
    if (!snap.exists) return null;
    return snap.data()?['groupId'] as String?;
  }

  @override
  Future<void> joinGroup(
      {required String groupId, required String displayName}) async {
    // 自分だけを追加。arrayUnion は読み取り不要なので、非メンバーでも
    // セキュリティルール（自己参加 update）の範囲で書き込める。
    await _db.doc('groups/$groupId').update({
      'memberIds': FieldValue.arrayUnion([_uid]),
      'members': FieldValue.arrayUnion([
        {'id': _uid, 'displayName': displayName, 'isOwner': false},
      ]),
    });
  }
}

/// 招待コード生成（紛らわしい文字を除いた英数字8桁）。
String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rnd = Random.secure();
  return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((u) => u?.uid);
  }

  @override
  Stream<AuthUser?> userChanges() {
    // userChanges は link でメール/匿名フラグが変わったときも emit する。
    return _auth.userChanges().map(
          (u) => u == null
              ? null
              : AuthUser(
                  uid: u.uid,
                  isAnonymous: u.isAnonymous,
                  email: u.email,
                  displayName: u.displayName,
                ),
        );
  }

  @override
  Future<String> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  @override
  Future<void> linkEmail(
      {required String email, required String password}) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser!.linkWithCredential(cred);
  }

  @override
  Future<void> linkGoogle() async {
    // Flutter Web: プロバイダ直渡しのポップアップで昇格（uid 不変）。
    await _auth.currentUser!.linkWithPopup(GoogleAuthProvider());
  }

  @override
  Future<void> signInWithEmail(
      {required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _auth.signInWithPopup(GoogleAuthProvider());
  }

  @override
  Future<void> updateDisplayName(String name) async {
    // updateDisplayName は currentUser を更新し userChanges を再 emit する。
    await _auth.currentUser!.updateDisplayName(name);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

// === モデル変換 ===

/// `groups/{groupId}/tasks/{taskId}` の1ドキュメントを [Task] へ。
/// groupId は親ドキュメント参照（parent.parent）から復元する。
Task _taskFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  return Task(
    id: doc.id,
    groupId: doc.reference.parent.parent?.id ?? '',
    title: data['title'] as String? ?? '',
    dueDate: _toDate(data['dueDate']) ?? DateTime.now(),
    hasTime: data['hasTime'] as bool? ?? false,
    dueTime: data['dueTime'] as String?,
    priority: _enumByName(Priority.values, data['priority'], Priority.mid),
    status: _enumByName(TaskStatus.values, data['status'], TaskStatus.notStarted),
    createdBy: data['createdBy'] as String? ?? '',
    assigneeId: data['assigneeId'] as String?,
    createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
    completedAt: _toDate(data['completedAt']),
    completedBy: data['completedBy'] as String?,
  );
}

Map<String, dynamic> _taskToMap(Task task) {
  return {
    'title': task.title,
    'dueDate': Timestamp.fromDate(task.dueDate),
    'hasTime': task.hasTime,
    'dueTime': task.dueTime,
    'priority': task.priority.name,
    'status': task.status.name,
    'createdBy': task.createdBy,
    'assigneeId': task.assigneeId,
    'createdAt': task.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(task.createdAt),
    'completedAt':
        task.completedAt == null ? null : Timestamp.fromDate(task.completedAt!),
    'completedBy': task.completedBy,
  };
}

Group _groupFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  final members = (data['members'] as List<dynamic>? ?? [])
      .map((m) => _memberFromMap(m as Map<String, dynamic>))
      .toList();
  return Group(
    id: doc.id,
    name: data['name'] as String? ?? '',
    members: members,
    isPremium: data['isPremium'] as bool? ?? false,
    memberLimit: (data['memberLimit'] as num?)?.toInt() ?? 6,
    notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
  );
}

Member _memberFromMap(Map<String, dynamic> m) {
  return Member(
    id: m['id'] as String? ?? '',
    displayName: m['displayName'] as String? ?? '',
    isOwner: m['isOwner'] as bool? ?? false,
  );
}

DateTime? _toDate(Object? v) =>
    v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
