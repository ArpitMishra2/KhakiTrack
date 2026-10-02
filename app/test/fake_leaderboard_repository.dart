import 'package:maidan/data/leaderboard_repository.dart';

/// In-memory communities and boards, mirroring the server rules.
class FakeLeaderboardRepository implements LeaderboardRepository {
  final List<({int id, String name, bool group, bool private, String code})>
  all = [];
  final Set<int> joined = {};
  final Set<int> owned = {};
  int createdToday = 0;
  bool isVisible = true;
  final List<({int? community, String metric, int week})> calls = [];

  /// Rows for a (community or 'all', metric, week) key; empty if missing.
  final Map<String, List<LeaderboardEntry>> boards = {};

  int _next = 1;

  int addCommunity(
    String name, {
    bool group = false,
    bool private = false,
    bool join = false,
  }) {
    final id = _next++;
    all.add((
      id: id,
      name: name,
      group: group,
      private: private,
      code: 'CODE${id.toString().padLeft(2, '0')}',
    ));
    if (join) joined.add(id);
    return id;
  }

  Community _view(
    ({int id, String name, bool group, bool private, String code}) c,
  ) => Community(
    id: c.id,
    name: c.name,
    kind: c.group ? 'group' : 'region',
    isPrivate: c.private,
    inviteCode: joined.contains(c.id) ? c.code : null,
    members: joined.contains(c.id) ? 1 : 0,
    isMember: joined.contains(c.id),
    isOwner: owned.contains(c.id),
  );

  @override
  Future<List<Community>> myCommunities() async => [
    for (final c in all)
      if (joined.contains(c.id)) _view(c),
  ];

  @override
  Future<List<Community>> search(String query) async {
    final q = cleanName(query)?.toLowerCase();
    return [
      for (final c in all)
        if (!c.private && (q == null || c.name.toLowerCase().contains(q)))
          _view(c),
    ];
  }

  @override
  Future<int> create(
    String name, {
    required bool group,
    required bool private,
  }) async {
    final n = cleanName(name)!;
    if (createdToday >= 3) throw const CommunityException('create_limit');
    if (!private &&
        all.any(
          (c) =>
              !c.private &&
              c.group == group &&
              c.name.toLowerCase() == n.toLowerCase(),
        )) {
      throw const CommunityException('name_taken');
    }
    createdToday++;
    final id = addCommunity(
      n,
      group: group,
      private: group && private,
      join: true,
    );
    owned.add(id);
    return id;
  }

  @override
  Future<void> join(int id) async => joined.add(id);

  @override
  Future<void> joinByCode(String code) async {
    final c = all.where((c) => c.code == code.trim().toUpperCase());
    if (c.isEmpty) throw const CommunityException('not_found');
    joined.add(c.first.id);
  }

  @override
  Future<void> leave(int id) async => joined.remove(id);

  @override
  Future<bool> visible() async => isVisible;

  @override
  Future<void> setVisible(bool v) async => isVisible = v;

  @override
  Future<List<LeaderboardEntry>> fetch(
    int? communityId,
    String metric, {
    int weekOffset = 0,
  }) async {
    calls.add((community: communityId, metric: metric, week: weekOffset));
    return boards['${communityId ?? 'all'}/$metric/$weekOffset'] ?? const [];
  }
}
