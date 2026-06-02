import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:todoapp/app.dart';
import 'package:todoapp/data/auth_repository.dart';
import 'package:todoapp/data/group_repository.dart';
import 'package:todoapp/data/task_repository.dart';
import 'package:todoapp/providers/repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('匿名サインイン後に5タブの下部ナビが表示される', (WidgetTester tester) async {
    // 実 Firebase を使わず InMemory/Mock に差し替えて起動する。
    final container = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository()),
      groupRepositoryProvider.overrideWithValue(InMemoryGroupRepository()),
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
    ]);
    addTearDown(container.dispose);
    await container.read(authRepositoryProvider).signInAnonymously();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TodoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('タスク'), findsWidgets);
    expect(find.text('Myタスク'), findsOneWidget);
    expect(find.text('統計'), findsOneWidget);
    expect(find.text('キャラ'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
