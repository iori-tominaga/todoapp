import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/group_stats.dart';
import '../../theme/app_tokens.dart';

/// ⑥ グループ統計 / ランキング。
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final stats = MockData.familyStats;
    final groupName = MockData.groups.first.name;

    return Scaffold(
      appBar: AppBar(title: Text('$groupName ・ 統計')),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: '期限内完了率',
                  value: '${(stats.onTimeRate * 100).round()}%',
                ),
              ),
              SizedBox(width: t.spaceMd),
              Expanded(
                child: _SummaryCard(
                  label: '平均消化時間',
                  value: '${stats.avgCompletionDays} 日',
                ),
              ),
            ],
          ),
          SizedBox(height: t.spaceLg),

          _SectionTitle('消化数ランキング'),
          for (final e in stats.completionRanking)
            _RankBar(
              entry: e,
              maxValue: stats.completionRanking.first.value,
              unit: '',
            ),
          SizedBox(height: t.spaceLg),

          _SectionTitle('消化スピード（早い順）'),
          for (final e in stats.speedRanking)
            _RankBar(
              entry: e,
              maxValue: stats.speedRanking.last.value,
              unit: '日',
              invert: true,
            ),
          SizedBox(height: t.spaceLg),

          _SectionTitle('消化数の推移（直近7日）'),
          SizedBox(
            height: 160,
            child: _WeeklyChart(values: stats.weeklyCompleted),
          ),
          SizedBox(height: t.spaceSm),
          Text('無料プランは直近のみ表示',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(t.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: t.spaceXs),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: t.seed, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spaceSm),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _RankBar extends StatelessWidget {
  const _RankBar({
    required this.entry,
    required this.maxValue,
    required this.unit,
    this.invert = false,
  });

  final RankingEntry entry;
  final double maxValue;
  final String unit;

  /// 値が小さいほど良い指標（スピード）のとき true。
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = entry.isMe ? t.priorityHigh : t.seed;
    final ratio = invert
        ? (maxValue == 0 ? 0.0 : (maxValue - entry.value) / maxValue * 0.8 + 0.2)
        : (maxValue == 0 ? 0.0 : entry.value / maxValue);

    final valueText = unit == '日'
        ? '${entry.value}$unit'
        : '${entry.value.toInt()}$unit';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.spaceXs),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(entry.memberName,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(t.radiusSm),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: c.maxWidth * ratio.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(t.radiusSm),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: t.spaceSm),
          SizedBox(
            width: 44,
            child: Text(valueText,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final spots = [
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i].toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 20)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: t.seed,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: t.seed.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
