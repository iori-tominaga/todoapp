import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_tokens.dart';

/// 招待リンク表示ダイアログ。
///
/// 発行済みリンクを表示し、コピー / 共有できる（共有はモック）。
/// 実際の発行は Universal Links / App Links を想定。
Future<void> showInviteLinkDialog(
  BuildContext context, {
  required String groupName,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _InviteLinkDialog(groupName: groupName),
  );
}

class _InviteLinkDialog extends StatelessWidget {
  const _InviteLinkDialog({required this.groupName});

  final String groupName;

  String get _link => 'https://grouptodo.app/invite/abc123';

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('招待リンク'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('「$groupName」への招待リンクを発行しました。',
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: t.spaceSm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(t.spaceSm),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(t.radiusSm),
            ),
            child: Text(_link,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          SizedBox(height: t.spaceXs),
          Text('リンクは7日間有効です。',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _link));
            if (context.mounted) {
              _snack(context, 'リンクをコピーしました');
            }
          },
          child: const Text('コピー'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _snack(context, '共有シートを開く（準備中）');
          },
          child: const Text('共有'),
        ),
      ],
    );
  }
}
