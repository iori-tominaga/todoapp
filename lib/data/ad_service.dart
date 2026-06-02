import 'package:flutter/material.dart';

/// 広告表示を抽象化する。
///
/// 本番は Google AdMob（メディエーション有効）。バナーはタスク一覧最下部、
/// 動画（インタースティシャル）はキャラクター画面への遷移時に出す（requirements.md §5）。
/// プレミアム（広告除去）ユーザーには出さない判定は呼び出し側で行う。
abstract class AdService {
  /// 全画面の動画広告を表示し、閉じられるまで待つ。
  /// 本番では AdMob の InterstitialAd / RewardedAd の load → show に対応。
  Future<void> showInterstitial(BuildContext context);
}

/// Mock 実装。Web では AdMob が動かないため、動画広告の代わりに
/// 「広告」ダイアログを出し、数秒のカウントダウン後に閉じられるようにする。
/// 実 SDK の「動画を最後まで見ると閉じられる」体験を最小限に模す。
class MockAdService implements AdService {
  @override
  Future<void> showInterstitial(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MockInterstitialDialog(),
    );
  }
}

/// AdMob 実装の差し込み口（作戦Aでは未配線）。
///
/// ネイティブ（iOS/Android）ビルドで `google_mobile_ads` を追加し、以下を実装する:
///
/// ```dart
/// // import 'package:google_mobile_ads/google_mobile_ads.dart';
///
/// @override
/// Future<void> showInterstitial(BuildContext context) async {
///   final completer = Completer<void>();
///   InterstitialAd.load(
///     adUnitId: '<AdMob のインタースティシャル広告ユニットID>',
///     request: const AdRequest(),
///     adLoadCallback: InterstitialAdLoadCallback(
///       onAdLoaded: (ad) {
///         ad.fullScreenContentCallback = FullScreenContentCallback(
///           onAdDismissedFullScreenContent: (ad) { ad.dispose(); completer.complete(); },
///         );
///         ad.show();
///       },
///       onAdFailedToLoad: (_) => completer.complete(), // 失敗時は遷移を止めない
///     ),
///   );
///   return completer.future;
/// }
/// ```
///
/// バナーは別途 `BannerAd` ＋ `AdWidget` をタスク一覧最下部に置く
/// （現在は `_AdBanner` プレースホルダ）。広告頻度は Remote Config で調整する。
class AdMobAdService implements AdService {
  @override
  Future<void> showInterstitial(BuildContext context) =>
      throw UnimplementedError('AdMob 配線はネイティブビルドで実装する');
}

class _MockInterstitialDialog extends StatefulWidget {
  const _MockInterstitialDialog();

  @override
  State<_MockInterstitialDialog> createState() =>
      _MockInterstitialDialogState();
}

class _MockInterstitialDialogState extends State<_MockInterstitialDialog> {
  int _remaining = 3;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (_remaining > 0 && mounted) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _remaining--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canClose = _remaining <= 0;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ondemand_video, size: 48),
            const SizedBox(height: 12),
            const Text('広告（Mock）',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('プレミアムにすると広告は表示されません。',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canClose ? () => Navigator.of(context).pop() : null,
              child: Text(canClose ? '閉じる' : '$_remaining 秒'),
            ),
          ],
        ),
      ),
    );
  }
}
