import 'dart:math';

import 'leaderboard_repository.dart';

/// "Rahul Mishra" -> "Rahul M."; a missing name becomes "You".
String shortName(String? displayName) {
  final parts = (displayName ?? '').trim().split(RegExp(r'\s+'))
    ..removeWhere((p) => p.isEmpty);
  if (parts.isEmpty) return 'You';
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last[0].toUpperCase()}.';
}

class _Area {
  _Area(this.id, this.name, this.kind, this.members, {this.private = false})
    : code = 'DEMO${id.toString().padLeft(2, '0')}';

  final int id;
  final String name;
  final String kind;
  final bool private;
  final String code;
  int members;
}

/// Made-up students in a made-up area (around Ghatampur, Kanpur Nagar), so
/// the rankings can be shown in detail in a pitch without touching real data.
/// Entirely in memory: nothing is read from or written to the server.
class DemoLeaderboardRepository implements LeaderboardRepository {
  DemoLeaderboardRepository({Future<String> Function()? myName})
    : _myName = myName ?? (() async => 'You');

  final Future<String> Function() _myName;

  static const _students = [
    'Vikas P.',
    'Suresh Y.',
    'Anil K.',
    'Mohit S.',
    'Deepak T.',
    'Amit V.',
    'Sandeep R.',
    'Pankaj D.',
    'Ravi K.',
    'Ajay S.',
    'Manoj G.',
    'Naveen B.',
    'Ankit C.',
    'Shivam T.',
    'Rohit Y.',
    'Kuldeep S.',
    'Pradeep M.',
    'Sumit K.',
    'Vishal J.',
    'Yogesh P.',
    'Harish N.',
    'Gaurav A.',
    'Lokesh B.',
    'Neeraj S.',
    'Brijesh K.',
    'Satish D.',
    'Jitendra R.',
    'Arvind P.',
    'Dinesh M.',
    'Tarun S.',
    'Akash V.',
    'Kapil Y.',
    'Mayank T.',
    'Sachin R.',
    'Pooja K.',
    'Neha Y.',
    'Anjali S.',
    'Ritu M.',
  ];

  final List<_Area> _areas = [
    _Area(1, 'Ghatampur Ground', 'region', 24),
    _Area(2, 'Sajeti Gaon', 'region', 11),
    _Area(3, 'Subah Ki Daud', 'group', 8),
    _Area(4, 'Bilhaur Maidan', 'region', 15),
    _Area(5, 'Kanpur Police Aspirants', 'group', 19),
    _Area(6, 'Maidan Academy Batch 7', 'group', 9, private: true),
  ];
  final Set<int> _joined = {1, 2, 3};
  final Set<int> _owned = {};
  final Set<int> _fresh = {};
  bool _visible = true;
  int _nextId = 100;

  Community _view(_Area a) => Community(
    id: a.id,
    name: a.name,
    kind: a.kind,
    isPrivate: a.private,
    inviteCode: _joined.contains(a.id) ? a.code : null,
    members: a.members,
    isMember: _joined.contains(a.id),
    isOwner: _owned.contains(a.id),
  );

  @override
  Future<List<Community>> myCommunities() async => [
    for (final a in _areas)
      if (_joined.contains(a.id)) _view(a),
  ];

  @override
  Future<List<Community>> search(String query) async {
    final q = cleanName(query)?.toLowerCase();
    return [
      for (final a in _areas)
        if (!a.private && (q == null || a.name.toLowerCase().contains(q)))
          _view(a),
    ];
  }

  @override
  Future<int> create(
    String name, {
    required bool group,
    required bool private,
  }) async {
    final n = cleanName(name)!;
    if (!private &&
        _areas.any(
          (a) =>
              !a.private &&
              a.kind == (group ? 'group' : 'region') &&
              a.name.toLowerCase() == n.toLowerCase(),
        )) {
      throw const CommunityException('name_taken');
    }
    final a = _Area(
      _nextId++,
      n,
      group ? 'group' : 'region',
      1,
      private: group && private,
    );
    _areas.add(a);
    _joined.add(a.id);
    _owned.add(a.id);
    _fresh.add(a.id);
    return a.id;
  }

  @override
  Future<void> join(int id) async {
    if (_joined.add(id)) {
      _areas.firstWhere((a) => a.id == id).members++;
    }
  }

  @override
  Future<void> joinByCode(String code) async {
    final hit = _areas.where((a) => a.code == code.trim().toUpperCase());
    if (hit.isEmpty) throw const CommunityException('not_found');
    await join(hit.first.id);
  }

  @override
  Future<void> leave(int id) async {
    if (_joined.remove(id)) {
      _areas.firstWhere((a) => a.id == id).members--;
    }
  }

  @override
  Future<bool> visible() async => _visible;

  @override
  Future<void> setVisible(bool visible) async => _visible = visible;

  @override
  Future<List<LeaderboardEntry>> fetch(
    int? communityId,
    String metric, {
    int weekOffset = 0,
  }) async {
    // A community the user just made has no runs yet.
    if (communityId != null && _fresh.contains(communityId)) return const [];
    final size = communityId == null
        ? 28
        : min(_areas.firstWhere((a) => a.id == communityId).members, 24);
    final rnd = Random(
      (communityId ?? 0) * 97 + metric.length * 31 + weekOffset * 13 + 5,
    );
    final names = [..._students]..shuffle(rnd);
    final count = min(size, names.length);
    final myRank = min(weekOffset == 0 ? 5 : 7, count);
    final me = await _myName();

    final values = <double>[];
    if (metric == 'pet') {
      // Seconds over 4.8 km: the fastest around 21:30, the slowest past the
      // 25:00 cut-off. Last week was a little slower for everyone.
      var t = 1285.0 + rnd.nextInt(50) + weekOffset * 18;
      for (var i = 0; i < count; i++) {
        values.add(t.roundToDouble());
        t += 9 + rnd.nextInt(34);
      }
    } else {
      // Km run this week: a long tail of casual runners.
      var km = 36.0 + rnd.nextInt(14) - weekOffset * 3;
      for (var i = 0; i < count; i++) {
        values.add(double.parse(km.toStringAsFixed(1)));
        km = max(4.0, km - (1.2 + rnd.nextDouble() * 3.2));
      }
    }
    return [
      for (var i = 0; i < count; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: i + 1 == myRank ? me : names[i],
          value: values[i],
          isMe: i + 1 == myRank,
        ),
    ];
  }
}

/// Uses the demo students while [isDemo] says so, the real server otherwise.
class SwitchableLeaderboards implements LeaderboardRepository {
  SwitchableLeaderboards({
    required this.real,
    required this.demo,
    required this.isDemo,
  });

  final LeaderboardRepository real;
  final LeaderboardRepository demo;
  final bool Function() isDemo;

  LeaderboardRepository get _r => isDemo() ? demo : real;

  @override
  Future<List<Community>> myCommunities() => _r.myCommunities();

  @override
  Future<List<Community>> search(String query) => _r.search(query);

  @override
  Future<int> create(
    String name, {
    required bool group,
    required bool private,
  }) => _r.create(name, group: group, private: private);

  @override
  Future<void> join(int id) => _r.join(id);

  @override
  Future<void> joinByCode(String code) => _r.joinByCode(code);

  @override
  Future<void> leave(int id) => _r.leave(id);

  @override
  Future<bool> visible() => _r.visible();

  @override
  Future<void> setVisible(bool visible) => _r.setVisible(visible);

  @override
  Future<List<LeaderboardEntry>> fetch(
    int? communityId,
    String metric, {
    int weekOffset = 0,
  }) => _r.fetch(communityId, metric, weekOffset: weekOffset);
}
