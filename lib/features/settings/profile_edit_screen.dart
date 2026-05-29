import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_tokens.dart';

/// プロフィール編集（表示名・アバター）。
///
/// 自分（[MockData.currentUserId]）の表示名を編集して保存（モック）。
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: MockData.currentUserName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('プロフィールを保存しました')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final initial =
        _controller.text.isEmpty ? '？' : _controller.text.substring(0, 1);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('プロフィール編集'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.spaceMd),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: t.seed.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                        color: t.seed,
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: t.seed,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                              content: Text('画像を選択（端末から / 準備中）')));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: t.spaceLg),
          Text('表示名', style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: t.spaceXs),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(),
          ),
          SizedBox(height: t.spaceLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
