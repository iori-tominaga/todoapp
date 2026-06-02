import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/repositories.dart';
import '../../theme/app_tokens.dart';
import 'auth_form_messages.dart';

/// アカウント登録（匿名 → 正式昇格）。
///
/// 匿名アカウントを Google / メール に昇格させる（[AuthRepository.linkEmail] /
/// [AuthRepository.linkGoogle]）。link は uid を変えないため、いまのデータを
/// そのまま引き継いで「機種変更しても消えない」状態にする。
class AccountRegisterScreen extends ConsumerStatefulWidget {
  const AccountRegisterScreen({super.key});

  @override
  ConsumerState<AccountRegisterScreen> createState() =>
      _AccountRegisterScreenState();
}

class _AccountRegisterScreenState extends ConsumerState<AccountRegisterScreen> {
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

  /// 昇格処理の共通ラッパ。成功時は userChanges が emit して画面が登録済み表示に変わる。
  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(okMessage)));
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = '登録に失敗しました。時間をおいて再度お試しください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _linkEmail() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'メールと6文字以上のパスワードを入力してください。');
      return;
    }
    _run(
      () => ref
          .read(authRepositoryProvider)
          .linkEmail(email: email, password: password),
      'メールで登録しました',
    );
  }

  void _linkGoogle() {
    _run(() => ref.read(authRepositoryProvider).linkGoogle(), 'Googleで登録しました');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = ref.watch(authUserProvider).value;
    final registered = user != null && !user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('アカウント登録'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          if (registered)
            _RegisteredCard(email: user.email)
          else ...[
            Text(
              '登録すると、機種変更やデータ削除をしても\nいまのデータを引き継げます。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: t.spaceLg),
            _ProviderButton(
              icon: Icons.g_mobiledata,
              label: 'Google で登録',
              onPressed: _busy ? null : _linkGoogle,
            ),
            SizedBox(height: t.spaceLg),
            Text('メールアドレスで登録',
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
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'パスワード（6文字以上）',
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
                onPressed: _busy ? null : _linkEmail,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('メールで登録'),
              ),
            ),
            SizedBox(height: t.spaceLg),
            Center(
              child: Text(
                '登録は任意です。匿名のままでも利用できます。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  const _RegisteredCard({this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(t.spaceMd),
        child: Row(
          children: [
            Icon(Icons.verified_user, color: t.statusDone),
            SizedBox(width: t.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('登録済み',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (email != null && email!.isNotEmpty)
                    Text(email!,
                        style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: t.spaceXs),
                  Text('このアカウントは別の端末でもログインできます。',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
