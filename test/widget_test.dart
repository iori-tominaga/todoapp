import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todoapp/app.dart';

void main() {
  testWidgets('起動して5タブの下部ナビが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    await tester.pumpAndSettle();

    expect(find.text('タスク'), findsOneWidget);
    expect(find.text('Myタスク'), findsOneWidget);
    expect(find.text('統計'), findsOneWidget);
    expect(find.text('キャラ'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
