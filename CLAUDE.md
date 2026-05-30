# CLAUDE.md（todoapp プロジェクト直下）

> このファイルはセッション開始時に自動で読み込まれる。
> 親の `../.claude/CLAUDE.md`（ころせんせいペルソナ）と併用すること。

## 作業を再開するとき（最重要）

コンテキストがクリアされた直後・新しいセッションの開始時は、
**まず `docs/progress.md` を読んでから作業を始める**こと。

`docs/progress.md` には次が書かれている:
- プロジェクト概要と確定方針（Riverpod / UI先行 / 差し替え可能デザイン）
- フェーズ進捗（今どこまで終わって、次に何をするか）
- 再開用のコマンド（flutter / スクショ / git）
- 未解決メモ

作業のキリが良いタイミングでは、`docs/progress.md` を最新状態に更新してから区切る。

## このリポジトリの要点

- Flutter + Riverpod（手書きNotifier）。UI先行 → 後でFirebase
- デザインは `lib/theme/app_tokens.dart` が唯一の真実。色/余白は `context.tokens` 経由（ハードコード禁止）
- 仕様: `docs/specs/requirements.md` / 画面: `docs/specs/wireframe.html`
- コミット・push はオーナーの明示依頼があるときのみ
