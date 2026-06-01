import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import 'group_providers.dart';
import 'repositories.dart';

/// 全グループのタスクを一元管理する Notifier。
///
/// 一覧・Myタスク・キャラ体調などはすべてこの状態から派生する。
/// 所属グループ（[groupsProvider]）のタスクを [TaskRepository.watchForGroups] で
/// 購読し、書き込みは [TaskRepository] 経由（書き込み後はストリーム再 emit で自動更新）。
class TasksNotifier extends StreamNotifier<List<Task>> {
  @override
  Stream<List<Task>> build() {
    final groupIds = ref.watch(groupsProvider).map((g) => g.id).toList();
    return ref.watch(taskRepositoryProvider).watchForGroups(groupIds);
  }

  /// ステータスを変更する。完了時は現在のユーザーを完了者として記録する。
  Future<void> changeStatus(Task task, TaskStatus status) async {
    final completedBy =
        status == TaskStatus.done ? ref.read(currentUserIdProvider) : null;
    await ref
        .read(taskRepositoryProvider)
        .updateStatus(task.groupId, task.id, status, completedBy);
  }

  /// 新規タスクを追加する。
  Future<void> add(Task task) async {
    await ref.read(taskRepositoryProvider).add(task);
  }
}

final tasksProvider = StreamNotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

/// 全タスクの同期スナップショット（ロード前は空リスト）。
/// 画面が触る派生 Provider はこれを起点に同期型を保つ。
List<Task> _tasksSnapshot(Ref ref) =>
    ref.watch(tasksProvider).value ?? const <Task>[];

/// 現在表示中グループのタスク（仕様 4.2 順にソート済み）。
final currentGroupTasksProvider = Provider<List<Task>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  final tasks =
      _tasksSnapshot(ref).where((t) => t.groupId == groupId).toList();
  tasks.sort(compareTasks);
  return tasks;
});

/// 自分が作成したタスク（全グループ横断・ソート済み）。
final myTasksProvider = Provider<List<Task>>((ref) {
  final me = ref.watch(currentUserIdProvider);
  final tasks = _tasksSnapshot(ref).where((t) => t.createdBy == me).toList();
  tasks.sort(compareTasks);
  return tasks;
});

/// 全グループの未完了タスク総数（キャラ体調の算出に使う）。
final totalPendingLoadProvider = Provider<int>((ref) {
  return _tasksSnapshot(ref).where((t) => t.status != TaskStatus.done).length;
});
