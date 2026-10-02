import 'package:maidan/data/leaderboard_repository.dart';

class FakeLeaderboardRepository implements LeaderboardRepository {
  FakeLeaderboardRepository({Area? area}) : area = area ?? const Area();

  Area area;
  final List<({String scope, String metric, int week})> calls = [];

  /// Rows returned for a (scope, metric, week) key; empty if missing.
  final Map<String, List<LeaderboardEntry>> boards = {};

  @override
  Future<List<District>> districts() async => const [
    District(id: 'agra', nameEn: 'Agra', nameHi: 'आगरा'),
    District(id: 'kanpur_nagar', nameEn: 'Kanpur Nagar', nameHi: 'कानपुर नगर'),
  ];

  @override
  Future<Area> myArea() async => area;

  @override
  Future<void> saveArea(Area a) async {
    area = Area(
      district: a.district,
      block: cleanPlace(a.block),
      village: cleanPlace(a.village),
      visible: a.visible,
    );
  }

  @override
  Future<List<LeaderboardEntry>> fetch(
    String scope,
    String metric, {
    int weekOffset = 0,
  }) async {
    calls.add((scope: scope, metric: metric, week: weekOffset));
    return boards['$scope/$metric/$weekOffset'] ?? const [];
  }
}
