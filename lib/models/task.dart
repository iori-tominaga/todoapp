import 'priority.dart';
import 'task_status.dart';

/// グループ内の1タスク。
///
/// Phase 1 ではモックデータ用の軽量モデル。
/// Phase 2 で Repository / Firestore と接続する際に整える。
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.hasTime = false,
    this.dueTime,
    required this.priority,
    this.status = TaskStatus.notStarted,
    required this.createdBy,
    this.assigneeId,
    required this.createdAt,
    this.completedAt,
    this.completedBy,
    this.groupId = '',
  });

  final String id;
  final String title;

  /// 所属グループID。インメモリ/Firestore どちらでもタスクの帰属先を表す。
  final String groupId;

  /// 期限の日付（必須）。時刻部分は無視し [dueTime] を正とする。
  final DateTime dueDate;

  /// 時間まで入力されたか。
  final bool hasTime;

  /// "HH:mm"（[hasTime] が true のとき有効）。
  final String? dueTime;

  final Priority priority;
  final TaskStatus status;

  final String createdBy;
  final String? assigneeId;

  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedBy;

  /// [completedAt] / [completedBy] は null を渡すと「変更なし」になってしまうため、
  /// 明示的にクリアできるよう sentinel ([_keep]) を既定値に使う。
  Task copyWith({
    String? groupId,
    TaskStatus? status,
    Object? completedAt = _keep,
    Object? completedBy = _keep,
  }) {
    return Task(
      id: id,
      title: title,
      dueDate: dueDate,
      hasTime: hasTime,
      dueTime: dueTime,
      priority: priority,
      status: status ?? this.status,
      createdBy: createdBy,
      assigneeId: assigneeId,
      createdAt: createdAt,
      completedAt:
          completedAt == _keep ? this.completedAt : completedAt as DateTime?,
      completedBy:
          completedBy == _keep ? this.completedBy : completedBy as String?,
      groupId: groupId ?? this.groupId,
    );
  }
}

/// copyWith で「引数が渡されなかった」ことを表す番兵。
const Object _keep = Object();

/// 仕様 4.2 の厳密な並び替えロジック。
///
/// 1. dueDate（日付）が早い順
/// 2. 同一日付内: 時間あり > 時間なし
/// 3. ともに時間あり: dueTime が早い順
/// 4. priority: high > mid > low
/// 5. createdAt が早い順（安定タイブレーク）
int compareTasks(Task a, Task b) {
  final da = DateTime(a.dueDate.year, a.dueDate.month, a.dueDate.day);
  final db = DateTime(b.dueDate.year, b.dueDate.month, b.dueDate.day);
  final d = da.compareTo(db);
  if (d != 0) return d;

  if (a.hasTime != b.hasTime) return a.hasTime ? -1 : 1;

  if (a.hasTime && b.hasTime) {
    final t = (a.dueTime ?? '').compareTo(b.dueTime ?? '');
    if (t != 0) return t;
  }

  final p = a.priority.rank.compareTo(b.priority.rank);
  if (p != 0) return p;

  return a.createdAt.compareTo(b.createdAt);
}
