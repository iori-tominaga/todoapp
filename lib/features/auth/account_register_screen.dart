import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';

/// アカウント登録（匿名 → 正式昇格）。
///
/// 匿名アカウントを Google / Apple / メール のいずれかに昇格させる（モック）。
/// 仕様 1：端末を変えてもデータを引き継げるようにするための導線。
class AccountRegisterScreen extends StatelessWidget {
  const AccountRegisterScreen({super.key});

  void _register(BuildContext context, String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$provider で登録（準備中）')));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('アカウント登録'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Text(
            '登録すると、機種変更しても\nデータを引き継げます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: t.spaceLg),
          _ProviderButton(
            icon: Icons.g_mobiledata,
            label: 'Google で登録',
            onPressed: () => _register(context, 'Google'),
          ),
          SizedBox(height: t.spaceSm),
          _ProviderButton(
            icon: Icons.apple,
            label: 'Apple で登録',
            onPressed: () => _register(context, 'Apple'),
          ),
          SizedBox(height: t.spaceSm),
          _ProviderButton(
            icon: Icons.mail_outline,
            label: 'メールアドレスで登録',
            onPressed: () => _register(context, 'メール'),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
