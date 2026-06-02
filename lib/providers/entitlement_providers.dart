import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'group_providers.dart';
import 'repositories.dart';

/// 購入で即時プレミアム化したグループIDの源（非同期）。画面には直接見せない。
final _purchasedPremiumStreamProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(entitlementRepositoryProvider).watchPremiumGroupIds(),
);

/// 購入済みプレミアムグループID（同期スナップショット・ロード前は空集合）。
final purchasedPremiumGroupIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(_purchasedPremiumStreamProvider).value ?? const <String>{},
);

/// 指定グループが実効的にプレミアムか。
///
/// 「最終的な真実」は Firestore の [Group.isPremium]（Cloud Function が同期）。
/// それに加えて、購入直後の即時反映（[purchasedPremiumGroupIdsProvider]）を OR する。
final effectiveIsPremiumProvider = Provider.family<bool, String>((ref, groupId) {
  final purchased = ref.watch(purchasedPremiumGroupIdsProvider).contains(groupId);
  if (purchased) return true;
  final groups = ref.watch(groupsProvider);
  final group = groups.where((g) => g.id == groupId);
  return group.isNotEmpty && group.first.isPremium;
});

/// 現在表示中のグループが実効的にプレミアムか（画面が最もよく使う形）。
final currentGroupIsPremiumProvider = Provider<bool>((ref) {
  final id = ref.watch(currentGroupIdProvider);
  return ref.watch(effectiveIsPremiumProvider(id));
});

/// ユーザーが広告除去（プレミアム）対象か。
///
/// プレミアムはグループ単位だが「グループ全員に適用」されるため、所属グループの
/// いずれかが実効プレミアムなら、その人は広告除去対象とみなす。キャラクター画面の
/// ような全グループ横断の画面で使う。
final userHasAnyPremiumProvider = Provider<bool>((ref) {
  final groups = ref.watch(groupsProvider);
  final purchased = ref.watch(purchasedPremiumGroupIdsProvider);
  return groups.any((g) => g.isPremium || purchased.contains(g.id));
});
