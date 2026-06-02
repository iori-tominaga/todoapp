import 'package:flutter_test/flutter_test.dart';

import 'package:todoapp/data/auth_repository.dart';
import 'package:todoapp/mock/mock_data.dart';

/// 作戦B: アカウント昇格（匿名→正式）とログイン（別端末引き継ぎ）の核を検証する。
///
/// 核心は「昇格しても uid が変わらない＝データを引き継げる」こと。
/// 実 FirebaseAuth は使わず MockAuthRepository で決定的に確かめる。
void main() {
  test('匿名サインインは匿名フラグ付きで開始する', () async {
    final auth = MockAuthRepository();
    addTearDown(auth.dispose);

    final uid = await auth.signInAnonymously();
    final user = await auth.userChanges().first;

    expect(uid, MockData.currentUserId);
    expect(user!.isAnonymous, isTrue);
    expect(user.email, isNull);
  });

  test('メール昇格しても uid は不変・isAnonymous=false・email が付く', () async {
    final auth = MockAuthRepository();
    addTearDown(auth.dispose);

    final before = await auth.signInAnonymously();
    await auth.linkEmail(email: 'family@example.com', password: 'secret123');
    final after = await auth.userChanges().first;

    expect(after!.uid, before, reason: '昇格で uid が変わるとデータを引き継げない');
    expect(after.isAnonymous, isFalse);
    expect(after.email, 'family@example.com');
  });

  test('Google昇格でも uid は不変・isAnonymous=false', () async {
    final auth = MockAuthRepository();
    addTearDown(auth.dispose);

    final before = await auth.signInAnonymously();
    await auth.linkGoogle();
    final after = await auth.userChanges().first;

    expect(after!.uid, before);
    expect(after.isAnonymous, isFalse);
    expect(after.email, isNotNull);
  });

  test('別端末ログインは同じ uid に戻り、認証ストリームが uid を流す', () async {
    final auth = MockAuthRepository();
    addTearDown(auth.dispose);

    await auth.signInWithEmail(email: 'family@example.com', password: 'secret123');
    final user = await auth.userChanges().first;
    final uid = await auth.authStateChanges().first;

    expect(user!.uid, MockData.currentUserId);
    expect(user.isAnonymous, isFalse);
    expect(uid, MockData.currentUserId, reason: 'ログインで以前のデータ（me）に戻れる');
  });

  test('サインアウトで未ログイン（null）になる', () async {
    final auth = MockAuthRepository();
    addTearDown(auth.dispose);

    await auth.signInAnonymously();
    await auth.signOut();

    expect(await auth.authStateChanges().first, isNull);
    expect(await auth.userChanges().first, isNull);
  });
}
