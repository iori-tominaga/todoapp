# Phase 6-B 手順書 — ネイティブ実SDK接続（RevenueCat / AdMob / Remote Config）

> Phase 6-A で課金・広告・設定値は **抽象化レイヤ＋Mock** まで完成済み。
> このドキュメントは、その Mock を **本物のネイティブSDK** に差し替えるための完全手順。
>
> ⚠️ **重要**: ここで使う `google_mobile_ads` / `purchases_flutter` は **Web 実装が無い**。
> よって本書の作業は **`flutter build web` では検証できない**。
> 必ず **Android エミュレータ / iOS シミュレータ / 実機** でビルド・確認すること。
> （Web パイプラインを壊さないため、本体コードは Phase 6-A の Mock のまま温存し、
> 　ネイティブ差し替えはこの手順に沿って **別途** 行う想定。）

---

## 0. 前提と全体像

| レイヤ | 抽象（Phase 6-A 完成済み） | Mock 実装 | ネイティブ実装（本書で配線） |
|---|---|---|---|
| 課金 | `EntitlementRepository` | `MockEntitlementRepository` | `RevenueCatEntitlementRepository` |
| 広告 | `AdService` | `MockAdService` | `AdMobAdService` |
| 設定値 | `appConfigProvider` | 既定値固定 | Firebase Remote Config |

差し替えは `lib/providers/repositories.dart` の Provider を Mock → 本番実装に向ける **1行** で行う（§5）。

エンタイトルメントの「最終的な真実」は **Firestore の `group.isPremium`**。
RevenueCat の購入 webhook を Cloud Function が受けて `groups/{id}.isPremium = true` を書く。
クライアント実装は **購入直後の即時反映オーバーレイ**（`watchPremiumGroupIds`）だけを担う。
（クライアントを信用しない設計：requirements.md §9）

---

## 1. RevenueCat（サブスク ¥600/月）

### 1-1. アカウント / ダッシュボード設定

1. https://app.revenuecat.com でプロジェクト作成。
2. **Entitlement** を1つ作成（識別子例：`premium`）。
3. **Product** を App Store Connect / Google Play Console で作成した月額サブスク（¥600）に紐付け。
4. **Offering**（例 `default`）に monthly パッケージとして登録。
5. iOS / Android それぞれの **API キー** を控える（後で `Purchases.configure` に渡す）。
6. **Webhook** を設定 → Cloud Function のエンドポイントを登録（§4）。

### 1-2. 依存追加

```yaml
# pubspec.yaml の dependencies に追加
  purchases_flutter: ^8.0.0   # ネイティブ専用（Web では使わない）
```

```bash
flutter pub get
```

### 1-3. 初期化（main.dart）

`Firebase.initializeApp` の後ろに追加：

```dart
import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';

// runApp の前で：
await Purchases.setLogLevel(LogLevel.info);
final apiKey = Platform.isIOS ? '<RevenueCat iOS API キー>'
                              : '<RevenueCat Android API キー>';
await Purchases.configure(PurchasesConfiguration(apiKey)
  // 匿名Authの uid を appUserID に合わせると、ユーザー突合が楽になる
  ..appUserID = FirebaseAuth.instance.currentUser?.uid);
```

### 1-4. `RevenueCatEntitlementRepository` 実装

`lib/data/entitlement_repository.dart` のスケルトンを置き換える完成形：

```dart
import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatEntitlementRepository implements EntitlementRepository {
  // 購入直後の即時反映オーバーレイ（Cloud Function 伝播待ちのギャップを埋める）
  final Set<String> _justPurchased = <String>{};
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  @override
  Stream<Set<String>> watchPremiumGroupIds() async* {
    yield Set.unmodifiable(_justPurchased);
    yield* _controller.stream;
  }

  @override
  Future<void> purchasePremium(String groupId) async {
    final offerings = await Purchases.getOfferings();
    final pkg = offerings.current?.monthly;
    if (pkg == null) throw StateError('monthly パッケージが未設定');
    // どのグループに対する購入かを webhook 側で判別できるよう属性に載せる
    await Purchases.setAttributes({'target_group_id': groupId});
    final info = await Purchases.purchasePackage(pkg); // 課金ダイアログ
    if (info.entitlements.active.containsKey('premium')) {
      _justPurchased.add(groupId);                     // 即時反映
      _controller.add(Set.unmodifiable(_justPurchased));
    }
    // 確定反映は webhook → Cloud Function → Firestore(group.isPremium) 経由
  }

  @override
  Future<void> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    // 復元時はサーバの group.isPremium が正。ここでは即時オーバーレイの再送のみ。
    if (info.entitlements.active.containsKey('premium')) {
      _controller.add(Set.unmodifiable(_justPurchased));
    }
  }

  void dispose() => _controller.close();
}
```

> 注意：`target_group_id` を webhook payload から拾える形にするか、
> 別途「購入意図（uid, groupId）」を Firestore に先行書き込みして突合する方式でもよい。
> グループ単位課金をどう webhook で確定させるかは §4 とセットで設計する。

---

## 2. Google AdMob（バナー＋インタースティシャル動画）

### 2-1. ダッシュボード設定

1. https://apps.admob.com でアプリを登録（iOS / Android 別々）。
2. **広告ユニット** を作成：
   - バナー（タスク一覧最下部）
   - インタースティシャル動画（キャラ画面遷移時）
3. **App ID** と各 **広告ユニットID** を控える。
4. （任意）メディエーション設定。

### 2-2. 依存追加

```yaml
# pubspec.yaml
  google_mobile_ads: ^5.1.0   # ネイティブ専用
```

### 2-3. プラットフォーム設定

**Android** — `android/app/src/main/AndroidManifest.xml` の `<application>` 内：

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXX~XXXXXXXX"/>
```

**iOS** — `ios/Runner/Info.plist`：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXX~XXXXXXXX</string>
```

### 2-4. 初期化（main.dart、ネイティブのみ）

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
// runApp 前：
await MobileAds.instance.initialize();
```

### 2-5. `AdMobAdService` 実装

`lib/data/ad_service.dart` の `showInterstitial` 完成形：

```dart
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobAdService implements AdService {
  @override
  Future<void> showInterstitial(BuildContext context) async {
    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: '<インタースティシャル広告ユニットID>',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        // 読み込み失敗時は画面遷移を止めない（UX優先）
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }
}
```

### 2-6. バナー（タスク一覧最下部）

現在 `tasks_screen.dart` の `_AdBanner` はプレースホルダ。ネイティブでは：

```dart
class _AdBanner extends StatefulWidget { const _AdBanner(); ... }

class _AdBannerState extends State<_AdBanner> {
  BannerAd? _ad;
  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: '<バナー広告ユニットID>',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }
  @override
  void dispose() { _ad?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
```

> バナーの出し分け（プレミアムなら非表示）は既に `tasks_screen.dart` で
> `if (!isPremium) const _AdBanner()` のガードが入っているのでそのまま機能する。

### 2-7. テスト用 ID

開発中は必ず **Google 公式テスト広告ID** を使う（自分の広告をクリックすると BAN）：
- Android バナー: `ca-app-pub-3940256099942544/6300978111`
- Android インタースティシャル: `ca-app-pub-3940256099942544/1033173712`
- iOS バナー: `ca-app-pub-3940256099942544/2934735716`
- iOS インタースティシャル: `ca-app-pub-3940256099942544/4411468910`

---

## 3. Firebase Remote Config（無料/有料境界・広告頻度）

### 3-1. 依存追加

```yaml
# pubspec.yaml （※これは Web もサポートあり）
  firebase_remote_config: ^6.0.0
```

### 3-2. ダッシュボード設定

Firebase Console → Remote Config で以下のパラメータを作成：

| キー | 型 | 既定値 |
|---|---|---|
| `free_group_limit` | number | 3 |
| `free_member_limit` | number | 6 |
| `stats_history_days` | number | 7 |
| `interstitial_every_n_visits` | number | 1 |

### 3-3. `appConfigProvider` 実装

`lib/providers/app_config.dart` を FutureProvider 化する案（初回 fetch を待つ）：

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final rc = FirebaseRemoteConfig.instance;
  await rc.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await rc.setDefaults(const {
    'free_group_limit': 3,
    'free_member_limit': 6,
    'stats_history_days': 7,
    'interstitial_every_n_visits': 1,
  });
  await rc.fetchAndActivate();
  return AppConfig(
    freeGroupLimit: rc.getInt('free_group_limit'),
    freeMemberLimit: rc.getInt('free_member_limit'),
    statsHistoryDays: rc.getInt('stats_history_days'),
    interstitialEveryNVisits: rc.getInt('interstitial_every_n_visits'),
  );
});
```

> ⚠️ `Provider` → `FutureProvider` に変えると、現在 `appConfigProvider` を
> 同期で `watch` している箇所（`group_providers.dart` / `group_create_screen.dart`）が
> `AsyncValue` 対応に要修正。手軽にやるなら **同期 Provider のまま** 残し、
> `main` で fetch 済みの値を `overrideWithValue` で注入する形が UI 変更ゼロで安全：
>
> ```dart
> // main.dart 内、RC fetch 後：
> runApp(ProviderScope(
>   overrides: [appConfigProvider.overrideWithValue(fetchedConfig)],
>   child: const App(),
> ));
> ```

---

## 4. Cloud Function（購入 webhook → Firestore 反映）

RevenueCat の購入確定を **サーバ側で** `group.isPremium` に反映する。
クライアントの自己申告を信用しない（requirements.md §9）。

概略（Node.js / 2nd gen functions の例）：

```js
// functions/index.js
const {onRequest} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
admin.initializeApp();

exports.revenuecatWebhook = onRequest(async (req, res) => {
  // 1. Authorization ヘッダで RevenueCat 共有シークレットを検証
  if (req.get('Authorization') !== `Bearer ${process.env.RC_WEBHOOK_SECRET}`) {
    return res.status(401).end();
  }
  const ev = req.body.event;
  // 2. target_group_id（subscriber attributes）を取り出す
  const groupId = ev?.subscriber_attributes?.target_group_id?.value;
  if (!groupId) return res.status(400).end();

  const active = ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION'].includes(ev.type);
  const expired = ['EXPIRATION', 'CANCELLATION'].includes(ev.type);
  if (active) {
    await admin.firestore().doc(`groups/${groupId}`).update({isPremium: true});
  } else if (expired) {
    await admin.firestore().doc(`groups/${groupId}`).update({isPremium: false});
  }
  res.status(200).end();
});
```

> ⚠️ Cloud Functions は **Blaze（従量）プラン** が必要。現状 Spark（無料）なので、
> ここを動かす段階で課金プランへの切り替え判断が要る（progress.md の制約参照）。
> それまでは「購入即時オーバーレイ（クライアント側 `_justPurchased`）」だけで体験を作り、
> 確定反映は後追いでも UX は成立する。

---

## 5. Mock → 本番への差し替え（最後の1〜3行）

`lib/providers/repositories.dart`：

```dart
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  final repo = RevenueCatEntitlementRepository();   // ← Mock から差し替え
  ref.onDispose(repo.dispose);
  return repo;
});

final adServiceProvider =
    Provider<AdService>((ref) => AdMobAdService());  // ← Mock から差し替え
```

Remote Config は §3-3 の `overrideWithValue` 方式なら `app_config.dart` 改変ゼロ。

---

## 6. 検証手順（生徒くん side / Web では不可）

```bash
# Android エミュレータ or 実機で
flutter run -d <android-device>

# 確認項目
# [ ] 非プレミアムでタスク一覧最下部にバナーが出る
# [ ] キャラ画面に移ると動画（テスト広告）が出て、閉じると遷移できる
# [ ] PremiumCard の「アップグレード」で課金ダイアログ → 完了後バナー/動画が消える
# [ ] 機種変更想定：restorePurchases でプレミアムが戻る
# [ ] Remote Config の free_group_limit を変えると上限が変わる
```

> リリースビルド前に **テスト広告IDを本番IDに差し替え**、
> RevenueCat / AdMob を **本番モード** に切り替えること。

---

## 7. チェックリスト（着手順）

- [ ] RevenueCat プロジェクト・Entitlement・Product・Offering 作成
- [ ] AdMob アプリ・広告ユニット作成、App ID をネイティブ設定に記載
- [ ] `pubspec.yaml` に3パッケージ追加 → `flutter pub get`
- [ ] `main.dart` で Purchases / MobileAds / RemoteConfig 初期化
- [ ] `RevenueCatEntitlementRepository` / `AdMobAdService` 実装（§1-4 / §2-5）
- [ ] `_AdBanner` を本物のバナーに（§2-6）
- [ ] Remote Config 配線（§3-3）
- [ ] Cloud Function + webhook（§4、Blaze 切替判断とセット）
- [ ] `repositories.dart` で Provider を本番実装へ差し替え（§5）
- [ ] Android/iOS 実機で全項目検証（§6）
