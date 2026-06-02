import 'dart:async';

import '../mock/mock_data.dart';

/// ログイン中ユーザーのアカウント情報。
///
/// uid に加えて「匿名のままか」「紐づくメール」を持つ。匿名→正式の昇格
/// （linkWithCredential）は uid を変えないため、uid だけでは登録状態を判別できない。
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  final String uid;
  final bool isAnonymous;
  final String? email;

  /// 表示名（FirebaseAuth の displayName が正本）。未設定は null。
  final String? displayName;
}

/// 認証を抽象化する。
///
/// Firebase 実装では [authStateChanges] が `FirebaseAuth.authStateChanges()`、
/// [signInAnonymously] が `signInAnonymously()` にそのまま対応する。
/// 昇格（link系）・別端末ログイン（signIn系）は uid を保ったまま、または
/// 既存アカウントの uid でサインインしてデータを引き継ぐ。
abstract class AuthRepository {
  /// ログイン中ユーザーのID。未ログインは null。最初に現在値を即時 emit する。
  Stream<String?> authStateChanges();

  /// アカウント情報の変化（昇格でメール/匿名フラグが変わったときも emit）。
  Stream<AuthUser?> userChanges();

  /// 匿名サインイン。成功するとユーザーIDを返す。
  Future<String> signInAnonymously();

  /// 匿名アカウントをメール＋パスワードに昇格する（uid 不変）。
  Future<void> linkEmail({required String email, required String password});

  /// 匿名アカウントを Google に昇格する（uid 不変）。
  Future<void> linkGoogle();

  /// 既存のメールアカウントでサインインする（別端末からの引き継ぎ）。
  Future<void> signInWithEmail({required String email, required String password});

  /// 既存の Google アカウントでサインインする（別端末からの引き継ぎ）。
  Future<void> signInWithGoogle();

  /// 自分の表示名を更新する（FirebaseAuth の displayName を正本にする）。
  Future<void> updateDisplayName(String name);

  /// サインアウト。
  Future<void> signOut();
}

/// モック実装。起動時は未ログイン。匿名サインインで [MockData.currentUserId]
/// （`'me'`）を採用し、Phase 4a のモックデータ（completedBy 等）と整合させる。
///
/// 昇格・ログインは同じ uid（`'me'`）のまま `isAnonymous`/`email` を切り替えて
/// 「データを引き継いだ」状態を模す。
class MockAuthRepository implements AuthRepository {
  AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  Stream<String?> authStateChanges() async* {
    yield _user?.uid;
    yield* _controller.stream.map((u) => u?.uid);
  }

  @override
  Stream<AuthUser?> userChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<String> signInAnonymously() async {
    _user = AuthUser(
        uid: MockData.currentUserId,
        isAnonymous: true,
        displayName: MockData.currentUserName);
    _controller.add(_user);
    return _user!.uid;
  }

  @override
  Future<void> linkEmail(
      {required String email, required String password}) async {
    final uid = _user?.uid ?? MockData.currentUserId;
    _user = AuthUser(
        uid: uid,
        isAnonymous: false,
        email: email,
        displayName: _user?.displayName);
    _controller.add(_user);
  }

  @override
  Future<void> linkGoogle() async {
    final uid = _user?.uid ?? MockData.currentUserId;
    _user = AuthUser(
        uid: uid,
        isAnonymous: false,
        email: 'me@gmail.com',
        displayName: _user?.displayName);
    _controller.add(_user);
  }

  @override
  Future<void> signInWithEmail(
      {required String email, required String password}) async {
    _user = AuthUser(
        uid: MockData.currentUserId,
        isAnonymous: false,
        email: email,
        displayName: _user?.displayName);
    _controller.add(_user);
  }

  @override
  Future<void> signInWithGoogle() async {
    _user = AuthUser(
        uid: MockData.currentUserId,
        isAnonymous: false,
        email: 'me@gmail.com',
        displayName: _user?.displayName);
    _controller.add(_user);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final u = _user ??
        const AuthUser(uid: MockData.currentUserId, isAnonymous: true);
    _user = AuthUser(
        uid: u.uid,
        isAnonymous: u.isAnonymous,
        email: u.email,
        displayName: name);
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
