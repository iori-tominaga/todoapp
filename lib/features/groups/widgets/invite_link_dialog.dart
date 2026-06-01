import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repositories.dart';
import '../../../theme/app_tokens.dart';

/// 招待リンク表示ダイアログ。
///
/// 開いた時に Firestore へ招待コードを発行し、`code → groupId` を引けるようにする。
/// 生成したリンク（現在の公開URL基準のハッシュルート）をコピー / 共有できる。
Future<void> showInviteLinkDialog(
  BuildContext context, {
  required String groupId,
  required String groupName,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _InviteLinkDialog(groupId: groupId, groupName: groupName),
  );
}

class _InviteLinkDialog extends ConsumerStatefulWidget {
  const _InviteLinkDialog({required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  ConsumerState<_InviteLinkDialog> createState() => _InviteLinkDialogState();
}

class _InviteLinkDialogState extends ConsumerState<_InviteLinkDialog> {
  String? _link;
  String? _error;

  @override
  void initState() {
    super.initState();
    _issue();
  }

  Future<void> _issue() async {
    try {
      final code =
          await ref.read(groupRepositoryProvider).createInvite(widget.groupId);
      if (!mounted) return;
      setState(() => _link = _buildLink(code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '発行に失敗しました: $e');
    }
  }

  /// 現在の公開URLを基準にハッシュルートの参加リンクを組み立てる。
  String _buildLink(String code) {
    final base = Uri.base;
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    return '$origin/#/join?code=$code';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = Theme.of(context).colorScheme;
    final link = _link;

    return AlertDialog(
      title: const Text('招待リンク'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('「${widget.groupName}」への招待リンクを発行しました。',
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: t.spaceSm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(t.spaceSm),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(t.radiusSm),
            ),
            child: _error != null
                ? Text(_error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: t.priorityHigh))
                : link == null
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: t.spaceSm),
                          Text('発行中…',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      )
                    : Text(link,
                        style: Theme.of(context).textTheme.bodySmall),
          ),
          SizedBox(height: t.spaceXs),
          Text('このリンクを家族に送ると、開いた人がグループに参加できます。',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        TextButton(
          onPressed: link == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (mounted) _snack('リンクをコピーしました');
                },
          child: const Text('コピー'),
        ),
      ],
    );
  }
}
