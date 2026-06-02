import 'dart:async';

/// 課金エンタイトルメント（プレミアム権利）を抽象化する。
///
/// 仕様: プレミアムは **グループ単位**。オーナーが支払うとグループ全員に適用される。
/// 本番では RevenueCat がエンタイトルメントを管理し、購入の webhook を受けた
/// Cloud Function が対象グループの `isPremium` を true に書き込む。
/// つまり「最終的な真実」は Firestore の `group.isPremium`（[Group.isPremium]）。
///
/// この Repository が抱えるのは **購入アクション** と **購入直後の即時反映**。
/// Cloud Function の伝播を待たずに UI を切り替えるためのオーバーレイ集合
/// （[watchPremiumGroupIds]）を提供する。
abstract class EntitlementRepository {
  /// このユーザーの操作で「プレミアム化した」グループID集合を流す。
  /// 最初に現在値を即 emit する（Firestore の `snapshots()` と同じ作法）。
  Stream<Set<String>> watchPremiumGroupIds();

  /// 指定グループのプレミアムを購入する（オーナーが払う→グループ全員に適用）。
  /// 本番では RevenueCat の `purchasePackage` を呼ぶ。
  Future<void> purchasePremium(String groupId);

  /// 過去の購入を復元する（機種変更後など）。本番では RevenueCat の
  /// `restorePurchases` → `customerInfo.entitlements` から復元する。
  Future<void> restorePurchases();
}

/// Mock 実装。購入したグループIDをメモリに保持し、即 emit する。
///
/// Web では RevenueCat ネイティブ SDK が動かないため、作戦A ではこの Mock で
/// 「購入→プレミアム反映（広告が消える）」を検証する。復元は no-op。
class MockEntitlementRepository implements EntitlementRepository {
  final Set<String> _premiumGroupIds = <String>{};
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  @override
  Stream<Set<String>> watchPremiumGroupIds() async* {
    yield Set.unmodifiable(_premiumGroupIds);
    yield* _controller.stream;
  }

  @override
  Future<void> purchasePremium(String groupId) async {
    // 実 SDK の課金ダイアログ往復を模した僅かな遅延。
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _premiumGroupIds.add(groupId);
    _controller.add(Set.unmodifiable(_premiumGroupIds));
  }

  @override
  Future<void> restorePurchases() async {
    _controller.add(Set.unmodifiable(_premiumGroupIds));
  }

  void dispose() => _controller.close();
}

/// RevenueCat 実装の差し込み口（作戦Aでは未配線）。
///
/// ネイティブ（iOS/Android）ビルドで `purchases_flutter` を追加し、以下を実装する:
///
/// ```dart
/// // import 'package:purchases_flutter/purchases_flutter.dart';
///
/// @override
/// Future<void> purchasePremium(String groupId) async {
///   final offerings = await Purchases.getOfferings();
///   final pkg = offerings.current!.monthly!;          // ¥600/月
///   await Purchases.purchasePackage(pkg);             // 課金ダイアログ
///   // 成功すると RevenueCat の webhook → Cloud Function が
///   // groups/{groupId}.isPremium = true を書き込み、Firestore 購読経由で反映される。
/// }
///
/// @override
/// Stream<Set<String>> watchPremiumGroupIds() {
///   // RevenueCat 側は「ユーザーがプレミアム権利を持つか」しか分からないため、
///   // グループ単位の反映は Firestore(group.isPremium) を正とする。
///   // ここは即時反映用オーバーレイのみ（購入直後に対象groupIdを足す）。
/// }
/// ```
///
/// エンタイトルメント判定はクライアントを信用せず、最終的にサーバ
/// （Cloud Function + Firestore ルール）で担保する（requirements.md §9）。
class RevenueCatEntitlementRepository implements EntitlementRepository {
  @override
  Stream<Set<String>> watchPremiumGroupIds() =>
      throw UnimplementedError('RevenueCat 配線はネイティブビルドで実装する');

  @override
  Future<void> purchasePremium(String groupId) =>
      throw UnimplementedError('RevenueCat 配線はネイティブビルドで実装する');

  @override
  Future<void> restorePurchases() =>
      throw UnimplementedError('RevenueCat 配線はネイティブビルドで実装する');
}
