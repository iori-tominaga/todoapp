import 'dart:async';

import '../mock/mock_data.dart';
import '../models/task.dart';
import '../models/task_status.dart';

/// タスクの読み書きを抽象化する。
///
/// 読み取りは [watchAll] のストリーム購読、書き込みは [Future] 型。
/// Firestore 実装では [watchAll] が `snapshots()`、書き込みが `set`/`update`
/// にそのまま対応する。差し替えはこの境界より内側だけで完結する。
abstract class TaskRepository {
  /// 全グループのタスクをリアルタイムに流す。最初に現在値を即時 emit する。
  Stream<List<Task>> watchAll();

  /// ステータスを変更する。完了にした場合は [completedBy] を記録し、
  /// 完了以外に戻した場合は完了情報をクリアする。
  Future<void> updateStatus(String taskId, TaskStatus status, String? completedBy);

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
  Stream<List<Task>> watchAll() async* {
    yield _snapshot();
    yield* _controller.stream;
  }

  @override
  Future<void> updateStatus(
      String taskId, TaskStatus status, String? completedBy) async {
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
