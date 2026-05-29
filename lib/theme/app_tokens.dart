import 'package:flutter/material.dart';

/// アプリ全体のデザイントークン。
///
/// 色・余白・角丸などの「見た目の値」をここに集約する。
/// ウィジェットはこれらの値を直書きせず、必ず [BuildContext.tokens] 経由で参照すること。
/// デザインを一新するときは、別の [AppTokens] インスタンスを作って差し替えるだけでよい。
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.seed,
    required this.scaffoldBackground,
    required this.surfaceCard,
    required this.priorityHigh,
    required this.priorityMid,
    required this.priorityLow,
    required this.statusNotStarted,
    required this.statusInProgress,
    required this.statusDone,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  /// ColorScheme を生成するためのシード色。
  final Color seed;

  /// アプリ全体の背景色（羊皮紙風の温かい地色）。
  final Color scaffoldBackground;

  /// カード等のサーフェス色（背景よりわずかに明るい紙色）。
  final Color surfaceCard;

  // 優先度カラー（仕様: 高=赤 / 中=黄 / 低=グレー）
  final Color priorityHigh;
  final Color priorityMid;
  final Color priorityLow;

  // ステータスカラー（未実施 / 着手中 / 完了）
  final Color statusNotStarted;
  final Color statusInProgress;
  final Color statusDone;

  // 余白スケール
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;

  // 角丸スケール
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  @override
  AppTokens copyWith({
    Color? seed,
    Color? scaffoldBackground,
    Color? surfaceCard,
    Color? priorityHigh,
    Color? priorityMid,
    Color? priorityLow,
    Color? statusNotStarted,
    Color? statusInProgress,
    Color? statusDone,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return AppTokens(
      seed: seed ?? this.seed,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityMid: priorityMid ?? this.priorityMid,
      priorityLow: priorityLow ?? this.priorityLow,
      statusNotStarted: statusNotStarted ?? this.statusNotStarted,
      statusInProgress: statusInProgress ?? this.statusInProgress,
      statusDone: statusDone ?? this.statusDone,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      seed: Color.lerp(seed, other.seed, t)!,
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      priorityHigh: Color.lerp(priorityHigh, other.priorityHigh, t)!,
      priorityMid: Color.lerp(priorityMid, other.priorityMid, t)!,
      priorityLow: Color.lerp(priorityLow, other.priorityLow, t)!,
      statusNotStarted: Color.lerp(statusNotStarted, other.statusNotStarted, t)!,
      statusInProgress: Color.lerp(statusInProgress, other.statusInProgress, t)!,
      statusDone: Color.lerp(statusDone, other.statusDone, t)!,
      spaceXs: _lerpDouble(spaceXs, other.spaceXs, t),
      spaceSm: _lerpDouble(spaceSm, other.spaceSm, t),
      spaceMd: _lerpDouble(spaceMd, other.spaceMd, t),
      spaceLg: _lerpDouble(spaceLg, other.spaceLg, t),
      spaceXl: _lerpDouble(spaceXl, other.spaceXl, t),
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// 現行デザイントークン：「ファンタジーだが温かみのある」世界観。
/// ブランド色は森のティールグリーン、地色は羊皮紙、アクセントは燠火・黄金・石のアース系。
/// 将来デザインを一新する場合は、この定数を別インスタンスに差し替える。
const AppTokens kDefaultTokens = AppTokens(
  seed: Color(0xFF1F9E8C), // 森のティールグリーン（ブランド色）
  scaffoldBackground: Color(0xFFF7F1E6), // 羊皮紙風の温かい地色
  surfaceCard: Color(0xFFFDFAF3), // 紙色（地色よりわずかに明るい）
  priorityHigh: Color(0xFFC15B3E), // 燠火レッド
  priorityMid: Color(0xFFD79A3C), // 黄金
  priorityLow: Color(0xFFA89F8C), // 石グレー
  statusNotStarted: Color(0xFFB3A993), // 砂色
  statusInProgress: Color(0xFFD98A3D), // 灯火アンバー
  statusDone: Color(0xFF2E9E8A), // ティール（達成）
  spaceXs: 4,
  spaceSm: 8,
  spaceMd: 16,
  spaceLg: 24,
  spaceXl: 32,
  radiusSm: 8,
  radiusMd: 12,
  radiusLg: 20,
);

/// `context.tokens` で現在のデザイントークンに簡単アクセスするための拡張。
extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
