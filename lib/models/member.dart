/// グループメンバー。
class Member {
  const Member({
    required this.id,
    required this.displayName,
    this.isOwner = false,
  });

  final String id;
  final String displayName;
  final bool isOwner;

  /// アバターに表示する頭文字（先頭1文字）。
  String get initial =>
      displayName.isEmpty ? '?' : displayName.substring(0, 1);
}
