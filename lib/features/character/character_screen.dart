import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_tokens.dart';

/// ⑦ キャラクター（体調・ステータス表示）。
///
/// 仕様では遷移時に動画広告（無料のみ）を差し込むが、広告は Phase 5。
/// 体調は全グループの未完了タスク総数から算出（[MockData.character]）。
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;
    final c = MockData.character;
    final condition = c.condition;

    final conditionColor = condition >= 70
        ? t.statusDone
        : condition >= 40
            ? t.priorityMid
            : t.priorityHigh;

    return Scaffold(
      appBar: AppBar(title: const Text('キャラクター')),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: t.seed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(t.radiusLg),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.stage.face, style: const TextStyle(fontSize: 64)),
                SizedBox(height: t.spaceSm),
                Text(c.stage.label,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          SizedBox(height: t.spaceLg),

          _Row(label: '体調', value: '$condition / 100'),
          SizedBox(height: t.spaceXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusSm),
            child: LinearProgressIndicator(
              value: condition / 100,
              minHeight: 14,
              backgroundColor: conditionColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(conditionColor),
            ),
          ),
          SizedBox(height: t.spaceMd),
          _Row(
            label: '残タスク（全グループ合計）',
            value: '${c.pendingLoad}',
            emphasize: true,
          ),
          SizedBox(height: t.spaceLg),

          Card(
            child: Padding(
              padding: EdgeInsets.all(t.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ステータス（装備＋体調で変動）',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  SizedBox(height: t.spaceSm),
                  _Row(label: '攻撃', value: '${c.attack}'),
                  _Row(label: '防御', value: '${c.defense}'),
                ],
              ),
            ),
          ),
          SizedBox(height: t.spaceMd),

          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('装備 ＜ 近日公開：ガチャ ＞'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spaceXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: emphasize
                ? Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: t.priorityHigh, fontWeight: FontWeight.w700)
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
