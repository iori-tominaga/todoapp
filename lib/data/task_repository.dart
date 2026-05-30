import '../mock/mock_data.dart';
import '../models/task.dart';
import '../models/task_status.dart';

/// タスクの読み書きを抽象化する。
///
/// Phase 2 ではインメモリ実装（同期API）。Phase 4 で Firestore 実装
/// （Stream/Future）に差し替える際、この境界より内側だけを変更する。
abstract class TaskRepository {
  /// 全グループのタスク（複製を返すので呼び出し側での破壊的変更は無効）。
  List<Task> all();

  /// ステータスを変更する。完了にした場合は [completedBy] を記録し、
  /// 完了以外に戻した場合は完了情報をクリアする。
  void updateStatus(String taskId, TaskStatus status, String? completedBy);

  /// 新規タスクを追加する。
  void add(Task task);
}

/// [MockData] をシードにしたインメモリ実装。
///
/// `tasksByGroup`（グループID→タスク）を平坦化し、各タスクに [Task.groupId] を付与する。
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository() {
    for (final entry in MockData.tasksByGroup.entries) {
      for (final task in entry.value) {
        _tasks.add(task.copyWith(groupId: entry.key));
      }
    }
  }

  final List<Task> _tasks = [];

  @override
  List<Task> all() => List.unmodifiable(_tasks);

  @override
  void updateStatus(String taskId, TaskStatus status, String? completedBy) {
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i < 0) return;
    final done = status == TaskStatus.done;
    _tasks[i] = _tasks[i].copyWith(
      status: status,
      completedBy: done ? completedBy : null,
      completedAt: done ? DateTime.now() : null,
    );
  }

  @override
  void add(Task task) => _tasks.add(task);
}
