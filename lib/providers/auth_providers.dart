import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories.dart';

/// 認証状態のストリーム源（非同期）。画面には直接見せず、同期型に畳んで使う。
final authStateProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// サインイン済みかどうか（同期）。go_router の認証ガードが参照する。
final isSignedInProvider = Provider<bool>(
  (ref) => (ref.watch(authStateProvider).value ?? '').isNotEmpty,
);
