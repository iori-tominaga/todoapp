import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'グループTodo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(kDefaultTokens, Brightness.light),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
