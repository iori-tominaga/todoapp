import 'dart:async';

import '../models/group.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'auth_repository.dart';
import 'group_repository.dart';
import 'task_repository.dart';

/// === Firestore / FirebaseAuth 実装のスケルトン（Phase 4c） ===
///
/// 実接続はまだ行わない。次の手順で有効化する（詳細は
/// `docs/specs/firebase-setup.md`）:
///   1. firebase_core / cloud_firestore / firebase_auth を pubspec に追加
///   2. FlutterFire CLI で firebase_options.dart を生成、main で initializeApp
///   3. 各メソッドのコメントを実コードへ置き換える
///   4. providers/repositories.dart のプロバイダを InMemory/Mock から
///      この実装へ 1 箇所ずつ差し替える
///
/// インターフェース（Stream watchAll ＋ Future 書き込み）は Phase 4a で
/// Firestore に合わせて設計済みなので、`snapshots()` がそのまま乗る。

class FirestoreTaskRepository implements TaskRepository {
  // 実接続時のコンストラクタ:
  //   final FirebaseFirestore _db;
  //   FirestoreTaskRepository(this._db);

  @override
  Stream<List<Task>> watchAll() {
    // 実接続時:
    //   return _db
    //       .collectionGroup('tasks')
    //       .snapshots()
    //       .map((snap) => snap.docs.map(_taskFromDoc).toList());
    // ※ groupId は親ドキュメント参照（doc.reference.parent.parent!.id）から復元。
    //   所属グループに絞る場合は where 句を併用する。
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }

  @override
  Future<void> updateStatus(
      String taskId, TaskStatus status, String? completedBy) {
    // 実接続時（groupId も引数に追加する想定）:
    //   final done = status == TaskStatus.done;
    //   return _db.doc('groups/$groupId/tasks/$taskId').update({
    //     'status': status.name,
    //     'completedBy': done ? completedBy : null,
    //     'completedAt': done ? FieldValue.serverTimestamp() : null,
    //   });
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }

  @override
  Future<void> add(Task task) {
    // 実接続時:
    //   return _db
    //       .collection('groups/${task.groupId}/tasks')
    //       .add(_taskToMap(task));
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }
}

class FirestoreGroupRepository implements GroupRepository {
  @override
  Stream<List<Group>> watchAll() {
    // 実接続時（uid は AuthRepository から渡す）:
    //   return _db
    //       .collection('groups')
    //       .where('memberIds', arrayContains: uid)
    //       .snapshots()
    //       .map((snap) => snap.docs.map(_groupFromDoc).toList());
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }
}

class FirebaseAuthRepository implements AuthRepository {
  @override
  Stream<String?> authStateChanges() {
    // 実接続時:
    //   return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }

  @override
  Future<String> signInAnonymously() async {
    // 実接続時:
    //   final cred = await FirebaseAuth.instance.signInAnonymously();
    //   return cred.user!.uid;
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }

  @override
  Future<void> signOut() {
    // 実接続時: return FirebaseAuth.instance.signOut();
    throw UnimplementedError('Phase 4c: docs/specs/firebase-setup.md 参照');
  }
}
