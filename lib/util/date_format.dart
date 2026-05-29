import '../models/task.dart';
import '../models/task_status.dart';

const _weekdayJa = ['月', '火', '水', '木', '金', '土', '日'];

/// 「6/1(日)」のような日付ラベル。
String formatDueDate(DateTime d) {
  final w = _weekdayJa[d.weekday - 1];
  return '${d.month}/${d.day}($w)';
}

/// タスク一覧の副題：「6/1(日) 18:00 ・ 田中が作成」。
String taskSubtitle(Task task, String creatorName) {
  final buf = StringBuffer(formatDueDate(task.dueDate));
  if (task.hasTime && task.dueTime != null) {
    buf.write(' ${task.dueTime}');
  }
  if (task.status == TaskStatus.done) {
    buf.write(' ・ 完了');
  } else {
    buf.write(' ・ $creatorNameが作成');
  }
  return buf.toString();
}
