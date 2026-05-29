import '../models/character_state.dart';
import '../models/group.dart';
import '../models/group_stats.dart';
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

  /// 指定グループのタスクを、誰の名前で表示するか引くためのヘルパ。
  static String memberName(String groupId, String userId) {
    if (userId == currentUserId) return '自分';
    final group = groups.firstWhere((g) => g.id == groupId);
    final m = group.members.where((m) => m.id == userId);
    return m.isEmpty ? '不明' : m.first.displayName;
  }

  /// 全グループの未完了タスク総数（キャラの体調算出用）。
  static int get totalPendingLoad {
    var n = 0;
    for (final list in tasksByGroup.values) {
      n += list.where((t) => t.status != TaskStatus.done).length;
    }
    return n;
  }

  static CharacterState get character => CharacterState(
        pendingLoad: totalPendingLoad,
        attack: 12,
        defense: 8,
      );

  static const GroupStats familyStats = GroupStats(
    onTimeRate: 0.82,
    avgCompletionDays: 1.4,
    completionRanking: [
      RankingEntry(memberName: '田中', value: 24),
      RankingEntry(memberName: '佐藤', value: 15),
      RankingEntry(memberName: '自分', value: 9, isMe: true),
      RankingEntry(memberName: '鈴木', value: 6),
    ],
    speedRanking: [
      RankingEntry(memberName: '佐藤', value: 0.8),
      RankingEntry(memberName: '田中', value: 1.2),
      RankingEntry(memberName: '自分', value: 1.9, isMe: true),
    ],
    weeklyCompleted: [2, 4, 3, 5, 6, 4, 7],
  );
}
