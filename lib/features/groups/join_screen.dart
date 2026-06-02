import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/repositories.dart';
import '../../theme/app_tokens.dart';

/// 招待リンク（`/join?code=XXXX`）の着地画面。
///
/// 表示名を入力して [参加] すると、未ログインなら匿名サインイン →
/// 招待コードから groupId を解決 → 自分を追加 → タスク画面へ。
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, required this.code});

  final String? code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final _displayNameController =
      TextEditingController(text: ref.read(currentDisplayNameProvider) ?? '');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  /// サインインを保証し、認証状態（uid）が Provider に伝播するまで待つ。
  /// これを待たずに [groupRepositoryProvider] を読むと、uid が空のまま
  /// joinGroup が走ってしまうため。
  Future<void> _ensureSignedIn() async {
    if (ref.read(currentUserIdProvider).isNotEmpty) return;
    await ref.read(authRepositoryProvider).signInAnonymously();
    if (ref.read(currentUserIdProvider).isNotEmpty) return;
    final completer = Completer<void>();
    final sub = ref.listenManual(authStateProvider, (_, next) {
      if ((next.value ?? '').isNotEmpty && !completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await completer.future.timeout(const Duration(seconds: 15));
    } finally {
      sub.close();
    }
  }

  Future<void> _join() async {
    final code = widget.code;
    final displayName = _displayNameController.text.trim();
    if (code == null || code.isEmpty) {
      setState(() => _error = '招待コードがありません');
      return;
    }
    if (displayName.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _ensureSignedIn();
      final repo = ref.read(groupRepositoryProvider);
      final groupId = await repo.resolveInvite(code);
      if (groupId == null) {
        setState(() {
          _submitting = false;
          _error = '招待リンクが無効か、期限切れです';
        });
        return;
      }
      await repo.joinGroup(groupId: groupId, displayName: displayName);
      ref.read(currentGroupIdProvider.notifier).select(groupId);
      if (!mounted) return;
      context.go('/tasks');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '参加に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Icons.group_add, size: 44, color: t.seed),
              ),
              SizedBox(height: t.spaceLg),
              Text('グループに参加',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: t.spaceXs),
              Text('表示名を入力して参加しましょう',
                  style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: t.spaceXl),
              TextField(
                controller: _displayNameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _join(),
                decoration: const InputDecoration(
                  labelText: 'あなたの表示名',
                  hintText: '例）ママ / たろう',
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: t.spaceSm),
                Text(_error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: t.priorityHigh)),
              ],
              SizedBox(height: t.spaceLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _join,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.onSurface,
                    foregroundColor: cs.surface,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('参加する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
