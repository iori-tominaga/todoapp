# 開発の進捗・再開ガイド（progress.md）

> このファイルは「コンテキストをクリアした後にスムーズ再開する」ための単一の道しるべ。
> 作業のキリが良いタイミングで必ず更新する。最終更新: 2026-05-30（Phase 2 完了時点）

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
| Phase 3 | 統計を実データ算出に差し替え（タスク履歴から集計） | ⏭ 次はここ |
| Phase 4 | Firebase接続（認証 + Firestore Repository実装） | 未着手 |
| Phase 5 | 広告・課金 | 未着手 |

---

## 2. Phase 2 でやったこと（直近の完了内容）

- `Task` モデルに `groupId` を追加。`copyWith` を番兵(`_keep`)パターンにし、完了系nullableをクリア可能に
- Repository層を新設: `lib/data/task_repository.dart` / `group_repository.dart`（抽象 + InMemory実装、MockDataから種を読む）
- Provider群を新設: `lib/providers/` 配下
  - `repositories.dart`（taskRepositoryProvider / groupRepositoryProvider）
  - `group_providers.dart`（currentUserId / groups / currentGroupId(Notifier) / currentGroup / memberNameOf）
  - `task_providers.dart`（tasksProvider(Notifier) / currentGroupTasks / myTasks / totalPendingLoad）
  - `character_providers.dart` / `stats_providers.dart`
- 全画面を Consumer 化し、`MockData.xxx` 直参照を Provider 購読へ置換
  （tasks / mytasks / character / stats / settings / group_list / group_settings）
- 未使用化した `MockData.memberName` / `totalPendingLoad` / `character` と未使用importを削除
- `flutter analyze` クリーン、`flutter build web` 成功、スクショ確認済み

### 設計のキモ
`TasksNotifier`（全タスク保持）→ `totalPendingLoadProvider` が watch → `characterProvider` が体調算出、の自動連鎖。
タスク完了を呼ぶだけでキャラ体調が自動更新される。これが手書きNotifierを選んだ理由。

---

## 3. 次の一手（Phase 3）

統計画面 `lib/features/stats/stats_screen.dart` が読む `statsProvider`（現状 `MockData.familyStats` 直返し）を、
`tasksProvider` のタスク履歴から実際に集計するロジックに差し替える。
- 期限内完了率 / 平均消化時間 / 消化数ランキング / スピードランキング / 直近7日の推移
- 集計は `lib/providers/stats_providers.dart` 内で `ref.watch(tasksProvider)` を元に算出
- 注意: モックタスクには完了履歴が少ないため、必要なら MockData にサンプル完了タスクを増やす

---

## 4. 再開時の手順（クリア後にここから始める）

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
- Phase 4 で Firebase 接続時、InMemory*Repository を Firestore実装へ差し替える
- `profile_edit_screen.dart` は意図的に `MockData.currentUserName` を使用中（Phase 4 認証で対応）
