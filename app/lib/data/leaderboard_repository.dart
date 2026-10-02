import 'package:supabase_flutter/supabase_flutter.dart';

/// A user-created region (public) or group (public or private by code).
class Community {
  const Community({
    required this.id,
    required this.name,
    required this.kind,
    required this.isPrivate,
    required this.members,
    required this.isMember,
    required this.isOwner,
    this.inviteCode,
  });

  factory Community.fromRow(Map<String, dynamic> r) => Community(
    id: r['id'] as int,
    name: r['name'] as String,
    kind: r['kind'] as String,
    isPrivate: r['is_private'] as bool,
    inviteCode: r['invite_code'] as String?,
    members: (r['members'] as num).toInt(),
    isMember: r['is_member'] as bool,
    isOwner: r['is_owner'] as bool,
  );

  final int id;
  final String name;
  final String kind; // region | group
  final bool isPrivate;

  /// Only known to members.
  final String? inviteCode;
  final int members;
  final bool isMember;
  final bool isOwner;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.value,
    required this.isMe,
  });

  factory LeaderboardEntry.fromRow(Map<String, dynamic> r) => LeaderboardEntry(
    rank: (r['rank'] as num).toInt(),
    name: r['name'] as String,
    value: (r['value'] as num).toDouble(),
    isMe: r['is_me'] as bool,
  );

  final int rank;
  final String name;

  /// Seconds for the PET board, km for the distance board.
  final double value;
  final bool isMe;
}

/// Why a community action failed: name_taken | create_limit | member_limit |
/// not_found | unknown.
class CommunityException implements Exception {
  const CommunityException(this.code);
  final String code;

  @override
  String toString() => 'CommunityException($code)';
}

abstract class LeaderboardRepository {
  Future<List<Community>> myCommunities();
  Future<List<Community>> search(String query);

  /// Returns the new community's id; the creator joins as owner.
  Future<int> create(String name, {required bool group, required bool private});
  Future<void> join(int id);
  Future<void> joinByCode(String code);
  Future<void> leave(int id);

  Future<bool> visible();
  Future<void> setVisible(bool visible);

  /// [communityId] null means everyone. [metric]: pet | distance.
  Future<List<LeaderboardEntry>> fetch(
    int? communityId,
    String metric, {
    int weekOffset = 0,
  });
}

/// Collapses spaces, as the server does, so names compare the same.
String? cleanName(String? s) {
  final t = s?.trim().replaceAll(RegExp(r'\s+'), ' ');
  return t == null || t.isEmpty ? null : t;
}

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<T> _rpc<T>(String fn, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(fn, params: params) as T;
    } on PostgrestException catch (e) {
      const known = {'name_taken', 'create_limit', 'member_limit', 'not_found'};
      throw CommunityException(
        known.contains(e.message) ? e.message : 'unknown',
      );
    }
  }

  List<Community> _rows(Object? rows) => (rows as List)
      .cast<Map<String, dynamic>>()
      .map(Community.fromRow)
      .toList();

  @override
  Future<List<Community>> myCommunities() async =>
      _rows(await _rpc<Object?>('list_communities', {'p_mine': true}));

  @override
  Future<List<Community>> search(String query) async => _rows(
    await _rpc<Object?>('list_communities', {
      'p_query': cleanName(query),
      'p_mine': false,
    }),
  );

  @override
  Future<int> create(
    String name, {
    required bool group,
    required bool private,
  }) async => await _rpc<int>('create_community', {
    'p_name': cleanName(name),
    'p_kind': group ? 'group' : 'region',
    'p_private': group && private,
  });

  @override
  Future<void> join(int id) => _rpc<Object?>('join_community', {'p_id': id});

  @override
  Future<void> joinByCode(String code) =>
      _rpc<Object?>('join_community', {'p_code': code.trim().toUpperCase()});

  @override
  Future<void> leave(int id) async {
    await _client
        .from('community_members')
        .delete()
        .eq('community_id', id)
        .eq('user_id', _uid);
  }

  @override
  Future<bool> visible() async {
    final r = await _client
        .from('profiles')
        .select('leaderboard_visible')
        .eq('id', _uid)
        .single();
    return r['leaderboard_visible'] as bool? ?? true;
  }

  @override
  Future<void> setVisible(bool visible) async {
    await _client
        .from('profiles')
        .update({'leaderboard_visible': visible})
        .eq('id', _uid);
  }

  @override
  Future<List<LeaderboardEntry>> fetch(
    int? communityId,
    String metric, {
    int weekOffset = 0,
  }) async {
    final rows = await _client.rpc(
      'leaderboard',
      params: {
        'p_community': communityId,
        'p_metric': metric,
        'p_week_offset': weekOffset,
      },
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromRow)
        .toList();
  }
}
