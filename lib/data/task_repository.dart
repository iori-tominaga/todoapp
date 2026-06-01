import 'dart:async';

import '../mock/mock_data.dart';
import '../models/task.dart';
import '../models/task_status.dart';

/// タスクの読み書きを抽象化する。
///
/// 読み取りは [watchForGroups] のストリーム購読、書き込みは [Future] 型。
/// Firestore 実装では [watchForGroups] が各グループの `snapshots()` マージ、
/// 書き込みが `set`/`update` に対応する。差し替えはこの境界より内側で完結する。
abstract class TaskRepository {
  /// 指定した所属グループ群のタスクをリアルタイムに流す（複数グループをマージ）。
  ///
  /// 全DB横断（collectionGroup）ではなく、メンバーであるグループだけを購読することで
  /// 非メンバーのタスクにクエリが触れず、セキュリティルールに弾かれない。
  Stream<List<Task>> watchForGroups(List<String> groupIds);

  /// ステータスを変更する。完了にした場合は [completedBy] を記録し、
  /// 完了以外に戻した場合は完了情報をクリアする。
  /// Firestore 実装はパス指定が必要なため [groupId] を受け取る。
  Future<void> updateStatus(
      String groupId, String taskId, TaskStatus status, String? completedBy);

  /// 新規タスクを追加する。
  Future<void> add(Task task);
}

/// [MockData] をシードにしたインメモリ実装。
///
/// `tasksByGroup`（グループID→タスク）を平坦化し、各タスクに [Task.groupId] を付与する。
/// 変更のたびに [_controller] へ最新リストを流すことで Firestore のリアルタイム
/// 購読を模した挙動にする。
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository() {
    for (final entry in MockData.tasksByGroup.entries) {
      for (final task in entry.value) {
        _tasks.add(task.copyWith(groupId: entry.key));
      }
    }
  }

  final List<Task> _tasks = [];
  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast();

  @override
  Stream<List<Task>> watchForGroups(List<String> groupIds) async* {
    final ids = groupIds.toSet();
    List<Task> filter(List<Task> all) =>
        all.where((t) => ids.contains(t.groupId)).toList();
    yield filter(_snapshot());
    yield* _controller.stream.map(filter);
  }

  @override
  Future<void> updateStatus(
      String groupId, String taskId, TaskStatus status, String? completedBy) async {
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final done = status == TaskStatus.done;
    _tasks[i] = _tasks[i].copyWith(
      status: status,
      completedBy: done ? completedBy : null,
      completedAt: done ? DateTime.now() : null,
    );
    _emit();
  }

  @override
  Future<void> add(Task task) async {
    _tasks.add(task);
    _emit();
  }

  void dispose() => _controller.close();

  List<Task> _snapshot() => List.unmodifiable(_tasks);

  void _emit() => _controller.add(_snapshot());
}
