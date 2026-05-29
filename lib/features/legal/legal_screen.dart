import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';

/// 利用規約 / プライバシーポリシー（静的表示）。
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('利用規約 / プライバシー'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          for (final section in _sections) ...[
            Text(section.$1, style: textTheme.titleMedium),
            SizedBox(height: t.spaceXs),
            Text(section.$2, style: textTheme.bodyMedium),
            SizedBox(height: t.spaceLg),
          ],
          Center(
            child: Text('最終更新: 2026-06-01',
                style: textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

const List<(String, String)> _sections = [
  (
    '利用規約',
    '本アプリはグループでタスクを共有・管理するためのサービスです。'
        'グループ内のタスクやステータスは、同じグループのメンバー全員に共有されます。'
        '利用者は、法令および公序良俗に反する目的で本アプリを利用しないものとします。',
  ),
  (
    'プライバシーポリシー',
    '本アプリは、アカウント情報・グループ情報・タスク情報を、'
        'サービス提供の目的の範囲内で取得・保存します。'
        '取得した情報を、本人の同意なく第三者へ提供することはありません。',
  ),
  (
    '課金について',
    'プレミアムプランはグループ単位の月額課金です。'
        'オーナーが購入すると、グループ全員に適用されます。'
        '解約はストアの定期購入管理から行えます。',
  ),
  (
    'お問い合わせ',
    'ご不明な点は、設定画面のサポート窓口よりお問い合わせください。',
  ),
];
