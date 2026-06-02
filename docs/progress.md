# 開発の進捗・再開ガイド（progress.md）

> このファイルは「コンテキストをクリアした後にスムーズ再開する」ための単一の道しるべ。
> 作業のキリが良いタイミングで必ず更新する。最終更新: 2026-06-02（Phase 5 実機検証OK・参加時タスク同期バグ修正済み）
>
> 🌐 公開URL: https://group-todo-d07c0.web.app （Firebase Hosting・最新ビルド配信済み）

---

## 0. これは何のプロジェクト？

家族向け**グループ共有Todoアプリ**（Flutter + Firebase）。
- 詳細仕様: `docs/specs/requirements.md`
- 画面イメージ: `docs/specs/wireframe.html`
- ペルソナ/作業ルール: 親ディレクトリの `../.claude/CLAUDE.md`（ころせんせい）

### 確定している方針（変更不可の前提）
- 状態管理: **Riverpod**。スタイルは**手書き Notifier**（コード生成・build_runner は使わない）
- 進め方: **UI先行 → 後で Firebase**。Repository パターンで mock⇄Firestore を差し替える
- デザイン: **差し替え可能**。`lib/theme/app_tokens.dart` が唯一の真実。色/余白は必ず `context.tokens` 経由（ハードコード禁止）
- デザイン世界観: 「ファンタジーだが温かみのある」、ターゲットは家族
- 作業環境: オーナーはスマホのみ。PC作業は Claude が全部やり、UIはスクショで届ける

---

## 1. フェーズ進捗

| Phase | 内容 | 状態 |
|---|---|---|
| Phase 0 | Flutterプロジェクト基盤 | ✅ 完了 |
| Phase 1 | 全画面をモックデータで実装 | ✅ 完了 |
| Phase 2 | Repository層 + Riverpod化（mock差し替え可能に） | ✅ 完了 |
| Phase 3 | 統計を実データ算出に差し替え（タスク履歴から集計） | ✅ 完了 |
| Phase 4 | 非同期土台 + 匿名認証 + Firestoreスケルトン（設計と土台） | ✅ 完了 |
| Phase 4-接続 | 実Firebase接続（Provider差し替え・実プロジェクト稼働） | ✅ 完了 |
| Phase 5 | グループ作成＋招待リンク＋参加（実DBを使える状態に） | ✅ 実機検証OK |
| Phase 6 | 広告・課金 | 未着手 |

---

## 2. Phase 4 でやったこと（直近の完了内容）

「実Firebaseはまだ繋がない。Firestore対応の**非同期土台＋匿名認証の配線**を
コードで完成させ、InMemory/Mock のまま動かす」方針（＝設計と土台）で実施。

### 4a: Repository を同期 → 非同期化（Stream/Future）
- `TaskRepository` を `Stream<List<Task>> watchAll()` ＋ `Future` 書き込みに変更。
  InMemory実装は `StreamController.broadcast` で再emit（`watchAll` は最初に現在値を
  即 yield → 以降 controller を流す。Firestore `snapshots()` がそのまま乗る形）
- `GroupRepository` も `watchAll()` Stream化
- `tasksProvider` を **`StreamNotifier`** 化（state は `AsyncValue<List<Task>>`）。
  書き込み後の手動 `state=` は不要に（ストリーム再emitで自動更新）
- **画面波及ゼロ**: 派生Provider（`currentGroupTasksProvider` 等）で
  `.value ?? const []` に畳み、画面が触る公開Providerの**同期型を維持**。
  `groupsProvider` も内部 `_groupsStreamProvider`(非公開) を同期Listに畳む

### 4b: 匿名認証の配線
- `AuthRepository`（`authStateChanges()` Stream ＋ `signInAnonymously()`）と
  `MockAuthRepository`（サインインで `'me'` を返し既存モックデータと整合）を追加
- `currentUserIdProvider` を認証由来に（**同期 `String` 維持**、未ログインは空文字）
- go_router を `routerProvider` 化＋**redirect 認証ガード**（未ログイン→`/onboarding`、
  サインイン→`/tasks`）。`refreshListenable` で認証状態変化を再評価
- onboarding「はじめる（匿名）」を本物の `signInAnonymously()` に配線
- 実フロー目視確認済み（URL `/onboarding`→`/tasks` 遷移、サインイン後タスク表示）

### 4c: Firestore実装スケルトン＋接続手順書
- `lib/data/firestore_repositories.dart` に Firestore/FirebaseAuth 実装の器
  （実コード例コメント＋`UnimplementedError`）。差し込み口を物理的に用意
- `docs/specs/firebase-setup.md` に**実接続手順書**（役割分担📱/💻・データ構造・
  セキュリティルール・Provider差し替え・残TODO）

### 設計のキモ（Phase 4 で確立し全サブで一貫）
**「内部Async源 → 派生で `.value ?? []` 同期畳み込み」**。
この型を4aで作ったので、4bの認証も同じ型に流すだけで済んだ。
画面コードは Phase 4 全体を通して**1行も変えていない**。

---

## 2.5. Phase 4-接続 でやったこと（実Firebase稼働）

「スケルトンを実Firebaseプロジェクトに繋ぐ」を完遂。**画面コードは無改修**で切替。

### 実プロジェクトと認証
- Firebaseプロジェクト **`group-todo-d07c0`**（Spark無料プラン・カード未登録＝課金なし）
- 匿名認証を有効化、Firestore作成（ロケーション設定済み）
- Firebase CLI でログイン（`re.zero.06onioni@gmail.com`）。
  📱スマホのみ環境のため winpty で PTY 確保＋FIFO で認証コード注入してOAuth突破
- FlutterFire CLI で `lib/firebase_options.dart` 生成（**gitignore済み・コミット禁止**）

### Provider 差し替え（mock → Firestore）
- `lib/providers/repositories.dart` を Firestore 実装に配線
  （`taskRepositoryProvider`=`FirestoreTaskRepository`、`groupRepositoryProvider`=
  uid付き`FirestoreGroupRepository`、`authRepositoryProvider`=`FirebaseAuthRepository`）。
  InMemory/Mock クラスはロールバック用に残置
- `lib/data/firestore_repositories.dart` をスケルトン→**実装に書き換え**
  （`collectionGroup('tasks').snapshots()`、`groups` を `memberIds arrayContains uid` で購読、
  `_taskFromDoc` は `reference.parent.parent?.id` で groupId 復元、enum は `.name` で直列化）
- `lib/main.dart` で `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`

### セキュリティルール（CLIデプロイ済み）
- `firestore.rules`：groups は `uid in resource.data.memberIds`、tasks は親groupの `get()` で判定
- `firebase.json`／`firestore.indexes.json` を整備し `firebase deploy` 系で配信

### 検証
- `flutter build web` 成功。`dev/verify_boot.mjs` で起動検証
  → コンソールに Firebase core/firestore/auth の初期化ログ、**エラー0件**、
  onboarding画面が正常描画。配線の成立を実証済み

---

## 2.6. Phase 5 でやったこと（グループ作成＋招待＋参加）

実DBを「使える状態」にした。招待は**URLリンク方式**。Cloud Function 不使用（Spark無料）。

### 作成・招待・参加（Repository＋UI）
- `GroupRepository` に `createGroup` / `createInvite` / `resolveInvite` / `joinGroup` を追加。
  Firestore実装は `memberIds:[uid]` / `members:[{自分,owner}]` を書き、参加は **arrayUnion**
  で自分だけ追加（読み取り不要＝非メンバーでもルール内で書ける）
- 招待は `invites/{code}`（8桁コード→groupId）。リンクは現在の公開URL基準で
  `…/#/join?code=XXXX` を生成（`Uri.base`、dart:html不要）
- UI: 空状態画面（`tasks_screen` の `_NoGroupsScreen`）に「作成」「招待リンクで参加」。
  `group_create_screen`（名前＋表示名で実書き込み）、`invite_link_dialog`（実コード発行）、
  `join_screen`（`/join?code=` 着地→匿名サインイン→解決→参加→`/tasks`）
- ルーター: `/join` を**認証ガードの例外**にして未ログインでも着地可能に

### タスク購読をマルチグループ安全に（Phase 4-接続の穴を塞いだ）
- `collectionGroup('tasks')` 全横断をやめ、**所属グループのtasksだけ購読してマージ**
  （`watchForGroups`）。`tasksProvider` を `groupsProvider` 依存に。非メンバーのtasksに
  クエリが触れないのでルールに弾かれない

### セキュリティルール（CLIデプロイ済み）
- groups: `allow create`（作成者=自分判定）／`allow update` は既存メンバー or `isSelfJoin()`
  （自分だけ追加・他人を消さない・name/isPremium/memberLimit不変）
- tasks: 親グループの `memberIds` で判定（従来どおり）
- invites: read=認証済み / create=そのグループのメンバー / update・delete=不可

### 配信・検証
- `firebase.json` に Hosting 追加。`flutter build web` → `firebase deploy`
  で **https://group-todo-d07c0.web.app** に公開
- `dev/verify_boot.mjs` でローカル／本番URLとも起動検証：Firebase初期化・**エラー0件**
- ✅ **実機で「作成→招待→参加→双方向同期」まで確認OK**（2026-06-02）

### 参加直後にタスクが見えないバグの修正（2026-06-02）
- 症状: 後から参加した人が、自分でタスクを1個追加するまで既存タスクを見られない
- 原因: 参加直後、タスク読み取りルールの `get(group)` が旧 `memberIds` を見て
  最初の `snapshots()` 購読が一瞬拒否される。Firestoreのリスナーは**エラーで切れると自力復活しない**
- 修正: `firestore_repositories.dart` の `watchForGroups` を**自己修復型**に。
  購読がエラーで切れたら1秒待って張り直し、権限伝播後に既存タスクを拾う（正常系は無影響）
- ⚠️ Flutter Web の Service Worker キャッシュが頑固。再デプロイ後はスマホで
  「Safari設定→詳細→Webサイトデータ」削除 or プライベートタブで最新版を読ませる

---

## 3. 次の一手

進行順は **C →（今ここ）→ B → A** で合意済み。

### ✅ C. 動作検証（完了・2026-06-02）
キャラ体調／統計の自動更新を `test/character_stats_reactive_test.dart` で検証済み（§5）。

### B. 仕上げ系TODOの消化（進行中）
- ✅ **アカウント昇格（匿名→メール/Google）＋別端末ログイン**（2026-06-02・コード/テスト/ビルド完了）。
  `AuthRepository` に link/signIn 系＋`userChanges()` 追加、`account_register_screen`/`login_screen` 実装、
  onboarding に「ログイン」導線、設定でアカウント状態を出し分け、ログアウトを実 signOut に修正。
  **⚠️ 実機稼働には📱Console でメール/パスワード＋Googleプロバイダの有効化が必要**
  （手順: `docs/specs/firebase-setup.md`「アカウント昇格を有効にする」）。有効化後に再デプロイ。
- ✅ **プロフィール実データ化（作戦A）**（2026-06-02・コード/テスト/ビルド完了）。
  表示名の正本を FirebaseAuth の `displayName` に統一。`AuthUser.displayName`＋`updateDisplayName()` 追加、
  `currentDisplayNameProvider` 新設、`profile_edit_screen` を実保存化（Mock依存を撤去）、
  グループ作成/参加の表示名欄を現在の表示名で初期値補完。
  ※既存グループの members 配列は遡及更新しない（次に作る/参加するグループから新名が反映される設計）。
- 残: 無料上限（3グループ/6人）のサーバ側強制、自己参加ルールの厳密化。

### A. Phase 6（広告・課金）へ（Bの後）
`_AdBanner`（tasks_screen）やグループ `isPremium` は既にUIにあるので課金導線から着手できる。

---

## 4. 再開時の手順（クリア後にここから始める）

> **いちばん簡単な再開方法**: 新しいセッションで `/resume` と打つ。
> 作業のキリ目でクリアする前は `/checkpoint` を打つと、このファイルが自動で最新化される。
> （コマンド定義: `.claude/commands/resume.md` / `checkpoint.md`）

手動で再開する場合:

1. このファイルと `docs/specs/requirements.md` を読む
2. `git log --oneline -5` で直近の到達点を確認
3. 必要なら下記コマンドで解析・ビルド・スクショ

### よく使うコマンド（PATH は Bash ツールで都度通す）
```bash
export PATH="$PATH:/c/Users/rezer/flutter/bin"
flutter analyze
flutter build web --no-tree-shake-icons
# ローカル配信（バックグラウンド）→ スクショ → 後始末
npx -y serve@14 build/web -l 8080      # run_in_background
node dev/screenshot.mjs http://localhost:8080
node dev/verify_boot.mjs http://localhost:8080   # 起動＋コンソールエラー検証
npx -y kill-port 8080

# Firebase（CLIはグローバル設置・PATH非経由なので node 直叩き）
FB="node $(npm root -g)/firebase-tools/lib/bin/firebase.js"
$FB deploy --only firestore:rules --project group-todo-d07c0
$FB deploy --only hosting        --project group-todo-d07c0   # → https://group-todo-d07c0.web.app
```
- スクショ出力: `dev/shots/*.png`（撮影対象は `dev/screenshot.mjs` の SCREENS）
- go_router はハッシュURL: `http://localhost:8080/#/<path>`（招待は `/#/join?code=XXXX`）
- 本番URL: https://group-todo-d07c0.web.app （Hosting・anon認証は web.app ドメイン自動許可）

### Git
- リモート: `origin = https://github.com/iori-tominaga/todoapp.git`
- コミットは明示依頼時のみ。push も明示依頼時のみ
- 秘密情報はコミットしない（google-services.json 等は .gitignore 済み）

---

## 5. 未解決メモ / TODO

- ✅ 作成→招待→参加→双方向同期は実機検証OK（2026-06-02）。参加直後の同期バグも修正済み（§2.6）
- **自己参加ルールの限界**: `members` 配列の中身（`isOwner` 等）はルールで検証していない。
  招待コード/groupIdが漏れなければ実害は低いが、厳密にやるなら map 内容の検証 or 招待ドキュメント側で制御
- グループ作成・参加に**無料上限（3グループ/6人）のサーバ側強制は未実装**（UI表記のみ）。必要なら後で
- ✅ キャラ体調の自動更新・統計の自動再計算は **Widgetテストで検証済み**（2026-06-02）。
  `test/character_stats_reactive_test.dart`：InMemory/Mockで完了→体調が再描画・統計が再集計されることを確認。
  実行: `flutter test test/character_stats_reactive_test.dart`
- 統計の7日推移は **今日起点**に修正済み（旧: 6/1月曜固定）。`stats_providers.dart`/`stats_screen.dart`
- `updateStatus` は `groupId` 引数を追加済み（Firestoreパス指定対応）
- `profile_edit_screen.dart` は FirebaseAuth `displayName` を読み書き（作戦Aで実データ化済み）
- アカウント昇格（匿名→Google/メール）は `account_register_screen.dart` がモックのまま
