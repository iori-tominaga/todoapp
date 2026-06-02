/// FirebaseAuthException の code を利用者向けの日本語メッセージに変換する。
///
/// 登録（link）とログイン（signIn）の両画面で共有する。未知の code は
/// 汎用メッセージにフォールバックする。
String authErrorMessage(String code) {
  switch (code) {
    case 'email-already-in-use':
    case 'credential-already-in-use':
    case 'account-exists-with-different-credential':
      return 'このメール／アカウントは既に使われています。ログイン画面からお試しください。';
    case 'invalid-email':
      return 'メールアドレスの形式が正しくありません。';
    case 'weak-password':
      return 'パスワードは6文字以上にしてください。';
    case 'wrong-password':
    case 'invalid-credential':
      return 'メールアドレスまたはパスワードが違います。';
    case 'user-not-found':
      return 'このメールアドレスのアカウントが見つかりません。';
    case 'user-disabled':
      return 'このアカウントは利用できません。';
    case 'too-many-requests':
      return '試行回数が多すぎます。しばらくしてからお試しください。';
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
      return 'ログインがキャンセルされました。';
    case 'network-request-failed':
      return 'ネットワークに接続できませんでした。';
    case 'operation-not-allowed':
      return 'この登録方法は現在無効です（管理者の有効化が必要）。';
    default:
      return '処理に失敗しました（$code）。時間をおいて再度お試しください。';
  }
}
