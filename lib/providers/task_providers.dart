import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import 'group_providers.dart';
import 'repositories.dart';

/// 全グループのタスクを一元管理するNotifier。
///
/// 一覧・Myタスク・キャラ体調などはすべてこの状態から派生する。
/// 変更は必ず [TaskRepository] を経由し、その結果で state を更新する。
class TasksNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() => ref.watch(taskRepositoryProvider).all();

  /// ステータスを変更する。完了時は現在のユーザーを完了者として記録する。
  void changeStatus(String taskId, TaskStatus status) {
    final repo = ref.read(taskRepositoryProvider);
    final completedBy =
        status == TaskStatus.done ? ref.read(currentUserIdProvider) : null;
    repo.updateStatus(taskId, status, completedBy);
    state = repo.all();
  }

  /// 新規タスクを追加する。
  void add(Task task) {
    final repo = ref.read(taskRepositoryProvider);
    repo.add(task);
    state = repo.all();
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

/// 現在表示中グループのタスク（仕様 4.2 順にソート済み）。
final currentGroupTasksProvider = Provider<List<Task>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  final tasks =
      ref.watch(tasksProvider).where((t) => t.groupId == groupId).toList();
  tasks.sort(compareTasks);
  return tasks;
});

/// 自分が作成したタスク（全グループ横断・ソート済み）。
final myTasksProvider = Provider<List<Task>>((ref) {
  final me = ref.watch(currentUserIdProvider);
  final tasks =
      ref.watch(tasksProvider).where((t) => t.createdBy == me).toList();
  tasks.sort(compareTasks);
  return tasks;
});

/// 全グループの未完了タスク総数（キャラ体調の算出に使う）。
final totalPendingLoadProvider = Provider<int>((ref) {
  return ref
      .watch(tasksProvider)
      .where((t) => t.status != TaskStatus.done)
      .length;
});
