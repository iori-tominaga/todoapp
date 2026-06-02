import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:todoapp/data/auth_repository.dart';
import 'package:todoapp/data/group_repository.dart';
import 'package:todoapp/data/task_repository.dart';
import 'package:todoapp/features/character/character_screen.dart';
import 'package:todoapp/features/stats/stats_screen.dart';
import 'package:todoapp/models/task_status.dart';
import 'package:todoapp/providers/character_providers.dart';
import 'package:todoapp/providers/repositories.dart';
import 'package:todoapp/providers/stats_providers.dart';
import 'package:todoapp/providers/task_providers.dart';
import 'package:todoapp/theme/app_theme.dart';
import 'package:todoapp/theme/app_tokens.dart';

/// 作戦C: 「タスク完了で キャラ体調 / 統計 が自動更新されるか」を検証する。
///
/// 検証の核心は watch→rebuild の最後の一区間（tasksProvider が更新されたとき、
/// 画面ウィジェットが再描画されるか）。本番Firestoreは使わず、InMemory/Mock
/// リポジトリで完全に決定的に確かめる。Firestore の再emit自体は Phase 5 の
/// 「双方向同期OK」で実機検証済みなので、ここでは扱わない。
void main() {
  // テスト環境ではフォントをネットワーク取得しない（フォールバックを使う）。
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// InMemory/Mock 実装で差し替えた ProviderContainer を作り、匿名サインイン済みにする。
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

  Widget host(ProviderContainer container, Widget child) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(kDefaultTokens, Brightness.light),
        home: child,
      ),
    );
  }

  testWidgets('タスクを完了すると キャラ体調が自動で再描画される', (tester) async {
    final container = await signedInContainer();
    await tester.pumpWidget(host(container, const CharacterScreen()));
    await tester.pumpAndSettle();

    // 完了前の体調・残数（プロバイダの実値を基準にする＝モック変更に強い）。
    final before = container.read(characterProvider);
    expect(before.pendingLoad, greaterThan(0), reason: '未完了タスクが種データに必要');
    expect(find.text('${before.condition} / 100'), findsOneWidget);

    // 全グループのどれか1件を完了にする。
    final tasks = container.read(tasksProvider).value!;
    final target = tasks.firstWhere((t) => t.status != TaskStatus.done);
    await container.read(tasksProvider.notifier).changeStatus(target, TaskStatus.done);
    await tester.pumpAndSettle();

    // プロバイダ: 残数が1減り、体調が回復している。
    final after = container.read(characterProvider);
    expect(after.pendingLoad, before.pendingLoad - 1);
    expect(after.condition, greaterThan(before.condition));

    // 画面: 古い体調表示は消え、新しい体調表示に置き換わっている（＝再描画された）。
    expect(find.text('${before.condition} / 100'), findsNothing);
    expect(find.text('${after.condition} / 100'), findsOneWidget);
  });

  testWidgets('タスクを完了すると 統計が自動で再集計され画面に反映される', (tester) async {
    final container = await signedInContainer();
    await tester.pumpWidget(host(container, const StatsScreen()));
    await tester.pumpAndSettle();

    // 画面が統計プロバイダにバインドされて描画できている。
    expect(find.text('消化数ランキング'), findsOneWidget);

    final before = container.read(statsProvider);
    final beforeTotal =
        before.completionRanking.fold<double>(0, (s, e) => s + e.value);

    // 現在表示中グループ（先頭=家族）の未完了タスクを1件完了にする。
    final groupId = container.read(currentGroupTasksProvider).first.groupId;
    final target = container
        .read(tasksProvider)
        .value!
        .firstWhere((t) => t.groupId == groupId && t.status != TaskStatus.done);
    await container.read(tasksProvider.notifier).changeStatus(target, TaskStatus.done);
    await tester.pumpAndSettle();

    final after = container.read(statsProvider);
    final afterTotal =
        after.completionRanking.fold<double>(0, (s, e) => s + e.value);

    // 集計が再計算された: 消化数合計が1増え、今日（推移グラフ末尾）も1増える。
    expect(afterTotal, beforeTotal + 1);
    expect(after.weeklyCompleted.last, before.weeklyCompleted.last + 1);

    // 画面が再集計後の値を描画している（サマリカードの期限内完了率）。
    expect(
      find.text('${(after.onTimeRate * 100).round()}%'),
      findsOneWidget,
    );
  });
}
