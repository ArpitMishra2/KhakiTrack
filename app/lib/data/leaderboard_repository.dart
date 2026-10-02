import 'package:supabase_flutter/supabase_flutter.dart';

class District {
  const District({
    required this.id,
    required this.nameEn,
    required this.nameHi,
  });

  factory District.fromRow(Map<String, dynamic> r) => District(
    id: r['id'] as String,
    nameEn: r['name_en'] as String,
    nameHi: r['name_hi'] as String,
  );

  final String id;
  final String nameEn;
  final String nameHi;

  String nameFor(String languageCode) => languageCode == 'hi' ? nameHi : nameEn;
}

/// The user's area, used to scope leaderboards.
class Area {
  const Area({this.district, this.block, this.village, this.visible = true});

  final String? district;
  final String? block;
  final String? village;

  /// Whether the user appears on other people's leaderboards.
  final bool visible;

  bool get hasDistrict => district != null;
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

abstract class LeaderboardRepository {
  Future<List<District>> districts();
  Future<Area> myArea();
  Future<void> saveArea(Area area);

  /// [scope]: village | block | district | state; [metric]: pet | distance.
  Future<List<LeaderboardEntry>> fetch(
    String scope,
    String metric, {
    int weekOffset = 0,
  });
}

/// Collapses spaces so "Ghatampur " and "Ghatampur" match.
String? cleanPlace(String? s) {
  final t = s?.trim().replaceAll(RegExp(r'\s+'), ' ');
  return t == null || t.isEmpty ? null : t;
}

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<List<District>> districts() async {
    final rows = await _client
        .from('districts')
        .select('id, name_en, name_hi')
        .order('name_en');
    return rows.map(District.fromRow).toList();
  }

  @override
  Future<Area> myArea() async {
    final r = await _client
        .from('profiles')
        .select('district, block, village, leaderboard_visible')
        .eq('id', _uid)
        .single();
    return Area(
      district: r['district'] as String?,
      block: r['block'] as String?,
      village: r['village'] as String?,
      visible: r['leaderboard_visible'] as bool? ?? true,
    );
  }

  @override
  Future<void> saveArea(Area area) async {
    await _client
        .from('profiles')
        .update({
          'district': area.district,
          'block': cleanPlace(area.block),
          'village': cleanPlace(area.village),
          'leaderboard_visible': area.visible,
        })
        .eq('id', _uid);
  }

  @override
  Future<List<LeaderboardEntry>> fetch(
    String scope,
    String metric, {
    int weekOffset = 0,
  }) async {
    final rows = await _client.rpc(
      'leaderboard',
      params: {
        'p_scope': scope,
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
