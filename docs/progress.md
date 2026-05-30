# 開発の進捗・再開ガイド（progress.md）

> このファイルは「コンテキストをクリアした後にスムーズ再開する」ための単一の道しるべ。
> 作業のキリが良いタイミングで必ず更新する。最終更新: 2026-05-30（Phase 3 完了時点）

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
| Phase 4 | Firebase接続（認証 + Firestore Repository実装） | ⏭ 次はここ |
| Phase 5 | 広告・課金 | 未着手 |

---

## 2. Phase 3 でやったこと（直近の完了内容）

- `stats_providers.dart` の `statsProvider` を、`MockData.familyStats` 直返しから
  **`tasksProvider` + `currentGroupId` の完了タスク履歴を集計する実装**へ差し替え
  - 期限内完了率（完了日 ≤ 期限日）/ 平均消化時間（作成→完了の日数, 小数1桁）
  - 消化数ランキング（completedBy 別カウント・多い順）
  - 消化スピードランキング（completedBy 別の平均日数・速い順）
  - 直近7日(月〜日)推移（**2026-06-01 月曜 起点に固定**。画面ラベルに合わせている）
  - 完了が0件のグループはゼロ値を返す安全分岐あり
- `lib/mock/mock_data.dart` に `_done` ヘルパーと `_familyDone`（完了履歴14件）を追加。
  各メンバーの傾向（消化数・スピード・期限内率）に差が出るよう日付/所要時間を調整
- 不要になった `MockData.familyStats` と `group_stats` import を削除
- `flutter analyze` クリーン、`flutter build web` 成功、`6-stats.png` で実データ表示を目視確認
  （完了率80% / 平均1.2日 / 田中6・佐藤4・自分3・鈴木2 / 推移 2,2,1,1,1,1,2）

### 仕組み: チェックポイント機構（このフェーズで新設）
コンテキスト枯渇でクオリティが落ちるのを防ぐため、キリ目でクリア→スムーズ再開できる仕組みを追加。
- `.claude/commands/checkpoint.md` … 区切る前に progress.md を最新化して「クリアOK」を案内
- `.claude/commands/resume.md` … クリア後の一発目。progress.md と git から状況を復元し次の一手を提示

### 設計のキモ（Phase 2 から継続）
`TasksNotifier`（全タスク保持）→ 各派生Providerが watch の自動連鎖。
統計も `tasksProvider` を watch しているので、タスクを完了するだけで各指標が再計算される。

---

## 3. 次の一手（Phase 4）

Firebase 接続。`InMemory*Repository` を Firestore 実装へ差し替える（境界は Repository の内側だけ）。
- 認証（匿名 or Google）で `currentUserId` を実値化（現状は `MockData.currentUserId` 固定）
- `task_repository.dart` / `group_repository.dart` の Firestore 版を実装し、同期APIを Stream/Future へ
- 統計の7日推移は今「2026-06-01 起点固定」。実データ接続時に**今日起点の直近7日**へ作り替える
- `google-services.json` 等の秘密情報はコミットしない（.gitignore 済み）

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

- キャラ体調の自動更新は**コード配線は正しいが実機タップでの目視確認は未**（静的スクショでは再現不可）
- 統計の自動再計算（タスク完了→数字が動く）も同様にコード配線は正しいが実機タップ確認は未
- 統計の7日推移は **2026-06-01 月曜 起点に固定**（モック期の暫定）。Phase 4 で今日起点へ
- Phase 4 で Firebase 接続時、InMemory*Repository を Firestore実装へ差し替える
- `profile_edit_screen.dart` は意図的に `MockData.currentUserName` を使用中（Phase 4 認証で対応）
