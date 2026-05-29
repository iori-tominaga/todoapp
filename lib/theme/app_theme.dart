import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// 指定したデザイントークンから [ThemeData] を生成する。
///
/// 見た目の決定はすべてここと [AppTokens] に集約されている。
/// デザインを一新するときは、渡す [tokens] を差し替えるだけでよい。
ThemeData buildAppTheme(AppTokens tokens, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.seed,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [tokens],
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
    ),
  );
}
