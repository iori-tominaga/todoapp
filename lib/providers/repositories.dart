import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/firestore_repositories.dart';
import '../data/group_repository.dart';
import '../data/task_repository.dart';
import 'auth_providers.dart';

/// データ層のProvider。実 Firebase 実装を返す。
///
/// InMemory/Mock 実装（[InMemoryTaskRepository] 等）は残してあり、
/// ここを差し戻すだけでモック動作にロールバックできる。
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => FirestoreTaskRepository(FirebaseFirestore.instance),
);

/// 所属グループは `memberIds arrayContains uid` で絞るため uid に依存する。
/// サインインで uid が変われば Provider が再構築され、購読が張り直される。
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final uid = ref.watch(authStateProvider).value ?? '';
  return FirestoreGroupRepository(FirebaseFirestore.instance, uid);
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);
