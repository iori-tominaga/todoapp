import '../models/group.dart';
import '../models/member.dart';
import '../models/priority.dart';
import '../models/task.dart';
import '../models/task_status.dart';

/// Phase 1 用のモックデータ。
///
/// Phase 2 で Repository（インメモリ → Firestore）に差し替える前提の仮置き。
/// 画面の見た目を確認するためだけに使う。
class MockData {
  MockData._();

  /// ログイン中ユーザーのID。
  static const String currentUserId = 'me';

  /// ログイン中ユーザーの表示名。
  static String get currentUserName => _me.displayName;

  // 表示を安定させるための基準日。
  static final DateTime _base = DateTime(2026, 6, 1, 9, 0);

  static const Member _me = Member(id: 'me', displayName: '自分', isOwner: true);
  static const Member _tanaka = Member(id: 'u_tanaka', displayName: '田中');
  static const Member _sato = Member(id: 'u_sato', displayName: '佐藤');
  static const Member _suzuki = Member(id: 'u_suzuki', displayName: '鈴木');

  static final List<Group> groups = [
    Group(
      id: 'g_family',
      name: '家族',
      isPremium: true,
      members: const [_me, _tanaka, _sato, _suzuki],
    ),
    Group(
      id: 'g_dev',
      name: '開発チーム',
      notificationsEnabled: false,
      members: const [
        Member(id: 'u_a', displayName: 'A'),
        Member(id: 'u_b', displayName: 'B'),
        Member(id: 'u_c', displayName: 'C'),
        Member(id: 'u_d', displayName: 'D'),
        _me,
        Member(id: 'u_e', displayName: 'E'),
      ],
    ),
    Group(
      id: 'g_circle',
      name: 'サークル',
      members: const [
        _me,
        Member(id: 'u_x', displayName: 'X'),
        Member(id: 'u_y', displayName: 'Y'),
      ],
    ),
  ];

  /// グループIDごとのタスク一覧。
  static final Map<String, List<Task>> tasksByGroup = {
    'g_family': [
      Task(
        id: 't1',
        title: '牛乳を買う',
        dueDate: _base,
        hasTime: true,
        dueTime: '18:00',
        priority: Priority.high,
        status: TaskStatus.notStarted,
        createdBy: _tanaka.id,
        createdAt: _base.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 't2',
        title: '書類を提出',
        dueDate: _base,
        priority: Priority.mid,
        status: TaskStatus.inProgress,
        createdBy: _me.id,
        createdAt: _base.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 't3',
        title: '部屋の掃除',
        dueDate: _base.add(const Duration(days: 2)),
        priority: Priority.low,
        status: TaskStatus.notStarted,
        createdBy: _me.id,
        createdAt: _base.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 't4',
        title: 'ゴミ出し',
        dueDate: _base.add(const Duration(days: 2)),
        priority: Priority.mid,
        status: TaskStatus.done,
        createdBy: _suzuki.id,
        createdAt: _base.subtract(const Duration(days: 3)),
        completedAt: _base.subtract(const Duration(hours: 5)),
        completedBy: _sato.id,
      ),
      ..._familyDone,
    ],
    'g_dev': [
      Task(
        id: 'd1',
        title: 'PRレビュー',
        dueDate: _base.add(const Duration(days: 1)),
        hasTime: true,
        dueTime: '10:00',
        priority: Priority.high,
        status: TaskStatus.inProgress,
        createdBy: 'u_a',
        createdAt: _base,
      ),
      Task(
        id: 'd2',
        title: 'リリースノート作成',
        dueDate: _base.add(const Duration(days: 3)),
        priority: Priority.mid,
        status: TaskStatus.notStarted,
        createdBy: _me.id,
        createdAt: _base,
      ),
    ],
    'g_circle': [
      Task(
        id: 'c1',
        title: '会場予約',
        dueDate: _base.add(const Duration(days: 5)),
        priority: Priority.high,
        status: TaskStatus.notStarted,
        createdBy: _me.id,
        createdAt: _base,
      ),
    ],
  };

  /// 完了タスクを簡潔に組み立てるヘルパー。
  /// [completed] 完了日時 / [due] 期限 / [hours] 作成→完了までの所要時間。
  static Task _done(
    String id,
    String title,
    String by, {
    required DateTime completed,
    required DateTime due,
    int hours = 24,
    Priority priority = Priority.mid,
  }) {
    return Task(
      id: id,
      title: title,
      dueDate: due,
      priority: priority,
      status: TaskStatus.done,
      createdBy: by,
      createdAt: completed.subtract(Duration(hours: hours)),
      completedAt: completed,
      completedBy: by,
    );
  }

  /// g_family の完了タスク履歴（統計の種データ）。
  /// 直近1週間(6/1〜6/7)に完了が散らばるよう配置し、消化数・スピード・
  /// 期限内完了率に差が出るよう各メンバーの傾向を変えてある。
  static final List<Task> _familyDone = [
    // --- 今週（6/1 月 〜 6/7 日）---
    _done('f5', '食器洗い', _tanaka.id,
        completed: DateTime(2026, 6, 1, 20), due: DateTime(2026, 6, 2), hours: 12),
    _done('f6', '保育園の書類記入', _me.id,
        completed: DateTime(2026, 6, 2, 21), due: DateTime(2026, 6, 3), hours: 30),
    _done('f7', '洗濯物たたみ', _sato.id,
        completed: DateTime(2026, 6, 2, 12), due: DateTime(2026, 6, 3), hours: 6),
    _done('f8', '風呂掃除', _tanaka.id,
        completed: DateTime(2026, 6, 3, 19), due: DateTime(2026, 6, 4), hours: 18),
    _done('f9', '庭の水やり', _suzuki.id,
        completed: DateTime(2026, 6, 4, 22), due: DateTime(2026, 6, 3), hours: 50),
    _done('f10', '電球の交換', _tanaka.id,
        completed: DateTime(2026, 6, 5, 9), due: DateTime(2026, 6, 6), hours: 8,
        priority: Priority.low),
    _done('f11', '買い出し', _sato.id,
        completed: DateTime(2026, 6, 6, 18), due: DateTime(2026, 6, 7), hours: 14,
        priority: Priority.high),
    _done('f12', '週末の献立決め', _me.id,
        completed: DateTime(2026, 6, 7, 15), due: DateTime(2026, 6, 8), hours: 36),
    _done('f13', '玄関の掃き掃除', _tanaka.id,
        completed: DateTime(2026, 6, 7, 11), due: DateTime(2026, 6, 8), hours: 20),
    // --- 先週（ランキングの厚み用・推移グラフには出ない）---
    _done('f14', '町内会費の集金', _tanaka.id,
        completed: DateTime(2026, 5, 26, 10), due: DateTime(2026, 5, 27), hours: 30),
    _done('f15', '不用品の回収依頼', _tanaka.id,
        completed: DateTime(2026, 5, 28, 16), due: DateTime(2026, 5, 27), hours: 20),
    _done('f16', '冷蔵庫の整理', _sato.id,
        completed: DateTime(2026, 5, 27, 9), due: DateTime(2026, 5, 28), hours: 40),
    _done('f17', '車の点検予約', _me.id,
        completed: DateTime(2026, 5, 29, 20), due: DateTime(2026, 5, 30), hours: 28),
    _done('f18', '実家へ電話', _suzuki.id,
        completed: DateTime(2026, 5, 30, 12), due: DateTime(2026, 5, 29), hours: 60),
  ];
}
