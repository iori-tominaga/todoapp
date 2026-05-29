import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// プレミアム案内カード（設定・グループ設定で共用）。
class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(t.spaceMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.seed, width: 1.5),
        color: t.seed.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: t.priorityMid, size: 20),
              SizedBox(width: t.spaceXs),
              Text('プレミアム',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: t.spaceXs),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: t.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('RevenueCat 経由で購入（オーナーが払うとグループ全員に適用）'),
                  ));
              },
              style: FilledButton.styleFrom(
                backgroundColor: cs.onSurface,
                foregroundColor: cs.surface,
              ),
              child: const Text('アップグレード'),
            ),
          ),
        ],
      ),
    );
  }
}
