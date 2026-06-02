import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 配信時に調整できるアプリ設定値（無料/有料境界・広告頻度・期間など）。
///
/// 仕様§9: これらは本番では **Firebase Remote Config** で配信時に変更できるように
/// する。「最初に決め切らず、リリース後に数値を見て寄せていける」状態を作るのが目的。
class AppConfig {
  const AppConfig({
    this.freeGroupLimit = 3,
    this.freeMemberLimit = 6,
    this.statsHistoryDays = 7,
    this.interstitialEveryNVisits = 1,
  });

  /// 無料プランで所属できるグループ数の上限。プレミアムは無制限。
  final int freeGroupLimit;

  /// 無料プランのグループ人数上限。プレミアムは無制限（大きな値）。
  final int freeMemberLimit;

  /// 無料プランで遡れる履歴・統計の日数。
  final int statsHistoryDays;

  /// キャラ画面遷移 N 回ごとに動画広告を出す頻度（1=毎回）。
  final int interstitialEveryNVisits;
}

/// アプリ設定値。作戦A ではデフォルト値を返す（Remote Config 未配線）。
///
/// 本番では Firebase Remote Config から取得して差し替える:
///
/// ```dart
/// // import 'package:firebase_remote_config/firebase_remote_config.dart';
/// final rc = FirebaseRemoteConfig.instance;
/// await rc.setDefaults({'free_group_limit': 3, 'free_member_limit': 6, ...});
/// await rc.fetchAndActivate();
/// return AppConfig(
///   freeGroupLimit: rc.getInt('free_group_limit'),
///   freeMemberLimit: rc.getInt('free_member_limit'),
///   statsHistoryDays: rc.getInt('stats_history_days'),
/// );
/// ```
final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
