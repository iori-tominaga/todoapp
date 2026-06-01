# Firebase 実接続 手順書（Phase 4c → 実接続）

> Phase 4 では「非同期Repository土台（4a）」「匿名認証の配線（4b）」「実装スケルトン（4c）」まで
> コードで完成済み。アプリは現在 `InMemory*Repository` / `MockAuthRepository` で動作している。
> この手順書どおりに進めると、**Provider を 3 箇所差し替えるだけ**で実 Firebase に切り替わる。

## 役割分担（重要）

オーナーはスマホのみ・PC作業は Claude が担当する前提。各ステップに担当を明記する。

| 記号 | 担当 | 内容 |
|---|---|---|
| 📱 | オーナー | Firebaseコンソール（ブラウザ操作）。スマホで可能 |
| 💻 | Claude | PC上のCLI・コード編集 |

---

## ステップ1 📱 Firebaseプロジェクトを作る

1. https://console.firebase.google.com/ をスマホブラウザで開く
2. 「プロジェクトを追加」→ 名前（例: `group-todo`）→ 作成
3. （Google Analyticsは任意。今は不要なのでオフでよい）

## ステップ2 📱 認証（匿名）を有効化

1. コンソール → 「Authentication」→「始める」
2. 「ログイン方法」→「匿名」を**有効化**して保存
   （※ 後で Google/メール昇格を実装する場合はそれらもここで有効化）

## ステップ3 📱 Firestore を作成

1. コンソール →「Firestore Database」→「データベースの作成」
2. 本番モードで開始 → ロケーションは `asia-northeast1`（東京）推奨

## ステップ4 💻 FlutterFire CLI で接続設定を生成

PCで Claude が実行する（オーナーのGoogleログインが一度だけ必要なので、
`! firebase login` をこのセッションで打ってもらう想定）。

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<プロジェクトID>
```

これで `lib/firebase_options.dart` が生成される（**コミットOK**: APIキーは
公開前提のクライアント識別子。実セキュリティは下記ルールで担保する）。
`google-services.json` / `GoogleService-Info.plist` は `.gitignore` 済み。

## ステップ5 💻 パッケージ追加

```bash
flutter pub add firebase_core cloud_firestore firebase_auth
```

## ステップ6 💻 main.dart で初期化

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: TodoApp()));
}
```

## ステップ7 💻 スケルトンを実装する

`lib/data/firestore_repositories.dart` の各メソッドのコメントを実コードへ。
モデル変換（`_taskFromDoc` / `_taskToMap` / `_groupFromDoc`）を追加する。

### Firestore データ構造（設計）

```
groups/{groupId}
  ├─ name: string
  ├─ isPremium: bool
  ├─ memberLimit: number
  ├─ memberIds: [uid, ...]        # クエリ用（where arrayContains）
  ├─ members: [{ id, displayName, isOwner }, ...]
  └─ tasks/{taskId}               # サブコレクション
       ├─ title, dueDate, dueTime, priority
       ├─ status: 'todo'|'doing'|'done'
       ├─ createdBy: uid, createdAt: timestamp
       └─ completedBy: uid?, completedAt: timestamp?
```

- 全タスク購読は `collectionGroup('tasks')`。`groupId` は
  `doc.reference.parent.parent!.id` から復元する。

## ステップ8 💻 Provider を差し替える

`lib/providers/repositories.dart`:

```dart
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => FirestoreTaskRepository(FirebaseFirestore.instance));
final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => FirestoreGroupRepository(FirebaseFirestore.instance, ref));
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository());
```

画面・派生Providerは **無改修**（Phase 4a/4b で境界を内側に封じたため）。

## ステップ9 📱 セキュリティルール

コンソール → Firestore →「ルール」に貼り付け:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.memberIds;
      match /tasks/{taskId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds;
      }
    }
  }
}
```

---

## 実接続時にあわせて直すTODO

- [ ] **統計の7日推移を「今日起点」へ**: `lib/providers/stats_providers.dart` は今
      `DateTime(2026, 6, 1)` 固定（モック期の暫定）。実データ接続時に
      `DateTime.now()` 起点の直近7日へ作り替える。画面の曜日ラベルも追従させる。
- [ ] `updateStatus` に `groupId` を引数追加（Firestoreはパス指定が必要なため）。
      呼び出し元 `TasksNotifier.changeStatus` も合わせて更新。
- [ ] `profile_edit_screen.dart` の `MockData.currentUserName` を認証プロフィールへ。
- [ ] アカウント昇格（匿名→Google/メール）の実装（`account_register_screen.dart`）。
