import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:todoapp/data/auth_repository.dart';
import 'package:todoapp/data/group_repository.dart';
import 'package:todoapp/data/task_repository.dart';
import 'package:todoapp/providers/entitlement_providers.dart';
import 'package:todoapp/providers/group_providers.dart';
import 'package:todoapp/providers/repositories.dart';

/// 作戦A: 「課金（Mock購入）でプレミアムが実効的に反映されるか」を検証する。
///
/// 本番Firestore/RevenueCat は使わず、InMemory/Mock で決定的に確かめる。
/// MockData では g_family が isPremium=true、g_dev / g_circle は非プレミアム。
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// InMemory/Mock で差し替えた ProviderContainer を作り、匿名サインイン済みにする。
  /// entitlementRepositoryProvider は既定の MockEntitlementRepository を使う。
  Future<ProviderContainer> signedInContainer() async {
    final container = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository()),
      groupRepositoryProvider.overrideWithValue(InMemoryGroupRepository()),
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
    ]);
    addTearDown(container.dispose);
    await container.read(authRepositoryProvider).signInAnonymously();
    return container;
  }

  /// グループ/エンタイトルメントのストリームを購読し続けて生かすための極小ホスト。
  Widget host(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          ref.watch(groupsProvider);
          ref.watch(purchasedPremiumGroupIdsProvider);
          return const SizedBox();
        }),
      ),
    );
  }

  testWidgets('Firestore由来の isPremium が実効プレミアムに反映される', (tester) async {
    final container = await signedInContainer();
    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();

    expect(container.read(effectiveIsPremiumProvider('g_family')), isTrue,
        reason: 'g_family は MockData で isPremium=true');
    expect(container.read(effectiveIsPremiumProvider('g_dev')), isFalse,
        reason: 'g_dev は非プレミアム');
  });

  testWidgets('購入すると非プレミアムのグループが実効プレミアムになる', (tester) async {
    final container = await signedInContainer();
    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();

    expect(container.read(effectiveIsPremiumProvider('g_dev')), isFalse);

    // 購入には実タイマー（SDK往復を模した遅延）が絡むため runAsync で回す。
    await tester.runAsync(() =>
        container.read(entitlementRepositoryProvider).purchasePremium('g_dev'));
    await tester.pumpAndSettle();

    expect(container.read(effectiveIsPremiumProvider('g_dev')), isTrue,
        reason: '購入直後オーバーレイで即時反映される');
    expect(container.read(purchasedPremiumGroupIdsProvider).contains('g_dev'),
        isTrue);
  });

  testWidgets('いずれかのグループがプレミアムなら広告除去対象になる', (tester) async {
    final container = await signedInContainer();
    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();

    // g_family が premium なので最初から広告除去対象。
    expect(container.read(userHasAnyPremiumProvider), isTrue);
  });
}
