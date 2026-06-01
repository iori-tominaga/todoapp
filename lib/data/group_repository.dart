import '../mock/mock_data.dart';
import '../models/group.dart';

/// グループの読み取りを抽象化する。
///
/// Firestore 実装では [watchAll] が所属グループの `snapshots()` に対応する。
abstract class GroupRepository {
  /// 所属グループをリアルタイムに流す。
  Stream<List<Group>> watchAll();
}

/// [MockData] をシードにしたインメモリ実装。グループは不変なので一度だけ emit する。
class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository() : _groups = List<Group>.from(MockData.groups);

  final List<Group> _groups;

  @override
  Stream<List<Group>> watchAll() async* {
    yield List.unmodifiable(_groups);
  }
}
