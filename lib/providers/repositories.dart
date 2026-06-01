import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/group_repository.dart';
import '../data/task_repository.dart';

/// データ層のProvider。
///
/// Phase 4 では、ここで返すインスタンスを Firestore 実装へ差し替えるだけで
/// 画面側は無改修のままデータソースを切り替えられる。
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final repo = InMemoryTaskRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => InMemoryGroupRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = MockAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
