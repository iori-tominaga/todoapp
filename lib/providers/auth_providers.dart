import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'repositories.dart';

/// 認証状態のストリーム源（非同期）。画面には直接見せず、同期型に畳んで使う。
final authStateProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// サインイン済みかどうか（同期）。go_router の認証ガードが参照する。
final isSignedInProvider = Provider<bool>(
  (ref) => (ref.watch(authStateProvider).value ?? '').isNotEmpty,
);

/// アカウント情報のストリーム源（昇格でメール/匿名フラグが変わると emit）。
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// 匿名のままかどうか（同期）。未ロード時は安全側で匿名扱い。
final isAnonymousProvider = Provider<bool>(
  (ref) => ref.watch(authUserProvider).value?.isAnonymous ?? true,
);

/// 紐づくメールアドレス（未登録は null）。
final currentEmailProvider = Provider<String?>(
  (ref) => ref.watch(authUserProvider).value?.email,
);

/// 自分の表示名（未設定は null）。プロフィール編集・グループ参加の初期値に使う。
final currentDisplayNameProvider = Provider<String?>(
  (ref) => ref.watch(authUserProvider).value?.displayName,
);
