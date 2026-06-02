import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/repositories.dart';
import '../../theme/app_tokens.dart';

/// ① オンボーディング / 認証。
///
/// 匿名で開始、またはアカウント登録。招待リンク経由なら自動で該当グループへ。
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(t.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: t.seed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(t.radiusLg),
                ),
                child: Icon(Icons.groups, size: 44, color: t.seed),
              ),
              SizedBox(height: t.spaceLg),
              Text('グループTodo',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: t.spaceXs),
              Text('みんなでタスクを共有・消化',
                  style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: t.spaceXl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(authRepositoryProvider).signInAnonymously();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.onSurface,
                    foregroundColor: cs.surface,
                  ),
                  child: const Text('はじめる（匿名）'),
                ),
              ),
              SizedBox(height: t.spaceSm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('ログイン（登録済みの方）'),
                ),
              ),
              SizedBox(height: t.spaceXl),
              Text(
                '招待リンク経由で開くと\n自動で該当グループへ参加します',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
