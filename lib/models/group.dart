import 'member.dart';

/// グループ。
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.members,
    this.isPremium = false,
    this.memberLimit = 6,
    this.notificationsEnabled = true,
  });

  final String id;
  final String name;
  final List<Member> members;
  final bool isPremium;
  final int memberLimit;

  /// このグループの通知ミュート状態（true=通知ON）。
  final bool notificationsEnabled;

  int get memberCount => members.length;

  Member get owner =>
      members.firstWhere((m) => m.isOwner, orElse: () => members.first);

  Group copyWith({bool? notificationsEnabled}) {
    return Group(
      id: id,
      name: name,
      members: members,
      isPremium: isPremium,
      memberLimit: memberLimit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
