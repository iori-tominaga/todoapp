import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/repositories.dart';
import '../../theme/app_tokens.dart';
import 'auth_form_messages.dart';

/// ログイン（別端末からの引き継ぎ）。
///
/// 既存のメール／Google アカウントでサインインする。成功すると authStateChanges が
/// uid を emit → ルーターの認証ガードが `/tasks` へ送る（この画面での明示遷移は不要）。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      // 成功時はルーターの redirect が /tasks へ遷移させる。
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'ログインに失敗しました。時間をおいて再度お試しください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _loginEmail() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'メールアドレスとパスワードを入力してください。');
      return;
    }
    _run(() => ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password));
  }

  void _loginGoogle() {
    _run(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('ログイン'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Text(
            '登録済みのアカウントでログインすると、\n以前のデータに戻れます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: t.spaceLg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _loginGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Google でログイン'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          SizedBox(height: t.spaceLg),
          Text('メールアドレスでログイン',
              style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceSm),
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          SizedBox(height: t.spaceSm),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'パスワード',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: t.spaceSm),
            Text(_error!,
                style: TextStyle(color: t.priorityHigh, fontSize: 13)),
          ],
          SizedBox(height: t.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _loginEmail,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('メールでログイン'),
            ),
          ),
        ],
      ),
    );
  }
}
