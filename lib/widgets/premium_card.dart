import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/entitlement_providers.dart';
import '../providers/group_providers.dart';
import '../providers/repositories.dart';
import '../theme/app_tokens.dart';

/// プレミアム案内カード（設定・グループ設定で共用）。
///
/// [groupId] 省略時は現在表示中のグループを対象にする。購入すると
/// [EntitlementRepository.purchasePremium] が走り、プレミアムが即時反映される
/// （広告が消える）。購入済みなら「有効」表示に切り替わる。
class PremiumCard extends ConsumerStatefulWidget {
  const PremiumCard({super.key, required this.subtitle, this.groupId});

  final String subtitle;
  final String? groupId;

  @override
  ConsumerState<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends ConsumerState<PremiumCard> {
  bool _busy = false;

  Future<void> _purchase(String groupId) async {
    if (groupId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(entitlementRepositoryProvider).purchasePremium(groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('プレミアムを有効にしました（グループ全員に適用）'),
        ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('購入に失敗しました。')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;
    final String groupId = widget.groupId ?? ref.watch(currentGroupIdProvider);
    final isPremium = ref.watch(effectiveIsPremiumProvider(groupId));

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
          Text(isPremium ? '有効中 ・ 広告なし ＋ 上級機能' : widget.subtitle,
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: t.spaceMd),
          if (isPremium)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: t.statusDone, size: 20),
                SizedBox(width: t.spaceXs),
                Text('プレミアム有効',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            color: t.statusDone, fontWeight: FontWeight.w700)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : () => _purchase(groupId),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.onSurface,
                  foregroundColor: cs.surface,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('アップグレード'),
              ),
            ),
        ],
      ),
    );
  }
}
