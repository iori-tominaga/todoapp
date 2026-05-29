import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// 指定したデザイントークンから [ThemeData] を生成する。
///
/// 見た目の決定はすべてここと [AppTokens] に集約されている。
/// デザインを一新するときは、渡す [tokens] を差し替えるだけでよい。
ThemeData buildAppTheme(AppTokens tokens, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.seed,
    brightness: brightness,
    // 羊皮紙の温かい地色をサーフェス系に反映（純白を避ける）。
    surface: tokens.surfaceCard,
  );

  final baseTextTheme = ThemeData(brightness: brightness).textTheme;
  // M PLUS Rounded 1c（丸ゴシック＝親しみやすさ）。
  final textTheme = GoogleFonts.mPlusRounded1cTextTheme(baseTextTheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [tokens],
    textTheme: textTheme,
    scaffoldBackgroundColor: tokens.scaffoldBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: tokens.scaffoldBackground,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.surfaceCard,
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
