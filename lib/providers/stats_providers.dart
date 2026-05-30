import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/mock_data.dart';
import '../models/group_stats.dart';

/// グループ統計。
///
/// Phase 2 では集計済みのモック値を返す。Phase 3 で
/// タスク履歴から実際に算出するロジックに差し替える。
final statsProvider = Provider<GroupStats>((ref) => MockData.familyStats);
