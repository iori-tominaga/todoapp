import 'dart:async';

import '../mock/mock_data.dart';

/// 認証を抽象化する。
///
/// Firebase 実装では [authStateChanges] が `FirebaseAuth.authStateChanges()`、
/// [signInAnonymously] が `signInAnonymously()` にそのまま対応する。
abstract class AuthRepository {
  /// ログイン中ユーザーのID。未ログインは null。最初に現在値を即時 emit する。
  Stream<String?> authStateChanges();

  /// 匿名サインイン。成功するとユーザーIDを返す。
  Future<String> signInAnonymously();

  /// サインアウト。
  Future<void> signOut();
}

/// モック実装。起動時は未ログイン。匿名サインインで [MockData.currentUserId]
/// （`'me'`）を採用し、Phase 4a のモックデータ（completedBy 等）と整合させる。
class MockAuthRepository implements AuthRepository {
  String? _userId;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  @override
  Stream<String?> authStateChanges() async* {
    yield _userId;
    yield* _controller.stream;
  }

  @override
  Future<String> signInAnonymously() async {
    _userId = MockData.currentUserId;
    _controller.add(_userId);
    return _userId!;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
