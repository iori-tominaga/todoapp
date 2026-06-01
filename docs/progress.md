# 開発の進捗・再開ガイド（progress.md）

> このファイルは「コンテキストをクリアした後にスムーズ再開する」ための単一の道しるべ。
> 作業のキリが良いタイミングで必ず更新する。最終更新: 2026-06-01（Phase 4 完了時点）

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
| Phase 4-接続 | 実Firebase接続（手順書どおりProvider差し替え） | ⏭ オーナー操作待ち |
| Phase 5 | 広告・課金 | 未着手 |

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

## 3. 次の一手

土台は完成済み。選択肢は2つ:

### A. 実Firebase接続（Phase 4-接続）
`docs/specs/firebase-setup.md` の手順どおり進める。要オーナー操作（📱コンソール:
プロジェクト作成・匿名認証有効化・Firestore作成・セキュリティルール）。
Claude側は FlutterFire 設定・スケルトン実装・Provider差し替え（💻）。画面は無改修で切替。
- `google-services.json` 等の秘密情報はコミットしない（.gitignore 済み）

### B. Phase 5（広告・課金）へ進む
実接続を後回しにし先に機能を積む。`_AdBanner`（tasks_screen）やグループ `isPremium` は
既にUIにあるので、課金導線から着手できる。

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
# 配信（バックグラウンド）→ スクショ → 後始末
npx -y serve@14 build/web -l 8080      # run_in_background
node dev/screenshot.mjs http://localhost:8080
npx -y kill-port 8080
```
- スクショ出力: `dev/shots/*.png`（撮影対象は `dev/screenshot.mjs` の SCREENS）
- go_router はハッシュURL: `http://localhost:8080/#/<path>`

### Git
- リモート: `origin = https://github.com/iori-tominaga/todoapp.git`
- コミットは明示依頼時のみ。push も明示依頼時のみ
- 秘密情報はコミットしない（google-services.json 等は .gitignore 済み）

---

## 5. 未解決メモ / TODO

- キャラ体調の自動更新・統計の自動再計算は**コード配線は正しいが実機タップ確認は未**（静的スクショでは再現不可）
- 統計の7日推移は **2026-06-01 月曜 起点に固定**（モック期の暫定）。実接続時に今日起点へ（手順書のTODO参照）
- 実接続時 `updateStatus` に `groupId` 引数が必要（Firestoreはパス指定）。`docs/specs/firebase-setup.md` 参照
- `profile_edit_screen.dart` は意図的に `MockData.currentUserName` を使用中（アカウント昇格実装時に対応）
- アカウント昇格（匿名→Google/メール）は `account_register_screen.dart` がモックのまま
