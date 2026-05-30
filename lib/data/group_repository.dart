import '../mock/mock_data.dart';
import '../models/group.dart';

/// グループの読み取りを抽象化する。
///
/// Phase 2 ではインメモリ実装。Phase 4 で Firestore 実装に差し替える。
abstract class GroupRepository {
  List<Group> all();
}

/// [MockData] をシードにしたインメモリ実装。
class InMemoryGroupRepository implements GroupRepository {
  InMemoryGroupRepository() : _groups = List<Group>.from(MockData.groups);

  final List<Group> _groups;

  @override
  List<Group> all() => List.unmodifiable(_groups);
}
