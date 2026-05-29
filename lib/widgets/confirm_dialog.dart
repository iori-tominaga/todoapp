import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 汎用の確認ダイアログ。
///
/// [確定] で true、[キャンセル] で false（外タップ含む）を返す。
/// [destructive] が true なら確定ボタンを警告色（高優先度カラー）にする。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  String cancelLabel = 'キャンセル',
  bool destructive = false,
}) async {
  final t = context.tokens;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: t.priorityHigh)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
