import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_settings.dart';
import '../data/leaderboard_repository.dart';
import '../data/training_logic.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'demo_badge.dart';
import 'language_button.dart';
import 'load_error.dart';

/// Weekly leaderboards: everyone, or one of the user's areas and groups.
class RankingTab extends StatefulWidget {
  const RankingTab({super.key, required this.boards});

  final LeaderboardRepository boards;

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  late Future<List<Community>> _mine = widget.boards.myCommunities();
  int? _community; // null: everyone
  List<Community> _mineLoaded = const [];
  String _metric = 'pet';
  int _week = 0;
  bool? _demoSeen;
  bool _loadRequested = false;
  late Future<List<LeaderboardEntry>> _entries = _fetch();

  Future<List<LeaderboardEntry>> _fetch() =>
      widget.boards.fetch(_community, _metric, weekOffset: _week);

  void _change(VoidCallback f) => setState(() {
    f();
    _entries = _fetch();
  });

  String _valueText(AppLocalizations l10n, LeaderboardEntry e) =>
      _metric == 'pet'
      ? formatDuration(e.value)
      : l10n.km(e.value.toStringAsFixed(1));

  void _share(AppLocalizations l10n, LeaderboardEntry e) {
    final name = _mineLoaded.where((c) => c.id == _community).firstOrNull?.name;
    SharePlus.instance.share(
      ShareParams(
        text: l10n.shareRankText(
          name ?? l10n.boardEveryone,
          e.rank,
          _valueText(l10n, e),
        ),
      ),
    );
  }

  Future<void> _manage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CommunitiesScreen(boards: widget.boards),
      ),
    );
    if (!mounted) return;
    final mine = widget.boards.myCommunities();
    final ids = (await mine).map((c) => c.id).toSet();
    setState(() {
      _mine = mine;
      if (_community != null && !ids.contains(_community)) _community = null;
      _entries = _fetch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final demo = SettingsScope.demoOf(context);
    // Switching demo mode swaps the data underneath: start over.
    if (_demoSeen != null && _demoSeen != demo) {
      _community = null;
      _mine = widget.boards.myCommunities();
      _entries = _fetch();
    }
    _demoSeen = demo;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (SettingsScope.lowDataOf(context) && !_loadRequested) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabRanking),
          actions: const [LanguageButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.lowDataRanking, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _loadRequested = true),
                  child: Text(l10n.loadRanking),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabRanking),
        actions: const [LanguageButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _change(() {});
          await _entries;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const DemoBadge(),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _manage,
                icon: const Icon(Icons.groups),
                label: Text(l10n.manageCommunities),
              ),
            ),
            FutureBuilder<List<Community>>(
              future: _mine,
              builder: (context, snap) {
                final mine = snap.data ?? const <Community>[];
                _mineLoaded = mine;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            avatar: const Icon(Icons.public, size: 18),
                            label: Text(l10n.boardEveryone),
                            selected: _community == null,
                            onSelected: (_) => _change(() => _community = null),
                          ),
                          for (final c in mine)
                            ChoiceChip(
                              avatar: Icon(
                                c.kind == 'group' ? Icons.groups : Icons.place,
                                size: 18,
                              ),
                              label: Text(c.name),
                              selected: _community == c.id,
                              onSelected: (_) =>
                                  _change(() => _community = c.id),
                            ),
                        ],
                      ),
                    ),
                    if (snap.hasData && mine.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.noCommunitiesYet,
                          style: textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.metricPet),
                    selected: _metric == 'pet',
                    onSelected: (_) => _change(() => _metric = 'pet'),
                  ),
                  ChoiceChip(
                    label: Text(l10n.metricDistance),
                    selected: _metric == 'distance',
                    onSelected: (_) => _change(() => _metric = 'distance'),
                  ),
                  ChoiceChip(
                    label: Text(l10n.thisWeek),
                    selected: _week == 0,
                    onSelected: (_) => _change(() => _week = 0),
                  ),
                  ChoiceChip(
                    label: Text(l10n.lastWeek),
                    selected: _week == 1,
                    onSelected: (_) => _change(() => _week = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<LeaderboardEntry>>(
              future: _entries,
              builder: (context, snap) {
                if (snap.hasError) {
                  return LoadError(onRetry: () => _change(() {}));
                }
                final rows = snap.data;
                if (rows == null) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (rows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Brand.khakiSoft,
                          ),
                          child: const Icon(
                            Icons.emoji_events_outlined,
                            size: 44,
                            color: Brand.olive,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.rankingEmpty, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final (i, e) in rows.indexed)
                      FadeSlideIn(
                        index: i,
                        child: _RankRow(
                          entry: e,
                          name: e.isMe
                              ? '${e.name} (${l10n.youLabel})'
                              : e.name,
                          value: _valueText(l10n, e),
                          shareTooltip: l10n.shareButton,
                          onShare: e.isMe ? () => _share(l10n, e) : null,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(l10n.rankingRules, style: textTheme.bodySmall),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String communityError(AppLocalizations l10n, CommunityException e) =>
    switch (e.code) {
      'name_taken' => l10n.errNameTaken,
      'create_limit' => l10n.errCreateLimit,
      'member_limit' => l10n.errMemberLimit,
      'not_found' => l10n.errCodeNotFound,
      'rate_limited' => l10n.errTooManyTries,
      _ => l10n.errCommunity,
    };

/// Search, join, create and leave areas and groups.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key, required this.boards});

  final LeaderboardRepository boards;

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final _query = TextEditingController();
  final _code = TextEditingController();
  final _newName = TextEditingController();
  late Future<List<Community>> _mine = widget.boards.myCommunities();
  late Future<List<Community>> _found = widget.boards.search('');
  late Future<bool> _visible = widget.boards.visible();
  bool _group = false;
  bool _private = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    _code.dispose();
    _newName.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {
    _mine = widget.boards.myCommunities();
    _found = widget.boards.search(_query.text);
  });

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      _refresh();
    } on CommunityException catch (e) {
      if (mounted) {
        setState(
          () => _error = communityError(AppLocalizations.of(context), e),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).errCommunity);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    Widget communityTile(Community c) => Card(
      child: ListTile(
        leading: Icon(c.kind == 'group' ? Icons.groups : Icons.place),
        title: Text(c.name),
        subtitle: Text(
          [
            c.kind == 'group' ? l10n.kindGroup : l10n.kindRegion,
            if (c.isPrivate) l10n.privateLabel,
            l10n.membersCount(c.members),
            if (c.isMember && c.inviteCode != null)
              '${l10n.inviteCodeLabel}: ${c.inviteCode}',
          ].join(' · '),
        ),
        trailing: c.isMember
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.inviteCode != null)
                    IconButton(
                      tooltip: l10n.inviteCodeShare(c.inviteCode!),
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: l10n.inviteCodeShare(c.inviteCode!),
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.codeCopied)),
                          );
                        }
                      },
                    ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _act(() => widget.boards.leave(c.id)),
                    child: Text(l10n.leaveLabel),
                  ),
                ],
              )
            : FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _act(() => widget.boards.join(c.id)),
                child: Text(l10n.joinLabel),
              ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.communitiesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.communitiesIntro),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: colors.error)),
            ),
          FutureBuilder<List<Community>>(
            future: _mine,
            builder: (context, snap) => Column(
              children: [
                for (final c in snap.data ?? const <Community>[])
                  communityTile(c),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _query,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.searchCommunities,
            ),
            onChanged: (q) => setState(() {
              _found = widget.boards.search(q);
            }),
          ),
          FutureBuilder<List<Community>>(
            future: _found,
            builder: (context, snap) {
              final list = (snap.data ?? const <Community>[])
                  .where((c) => !c.isMember)
                  .toList();
              if (snap.hasData &&
                  list.isEmpty &&
                  _query.text.trim().isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l10n.noCommunitiesFound),
                );
              }
              return Column(children: [for (final c in list) communityTile(c)]);
            },
          ),
          const Divider(height: 32),
          Text(l10n.joinByCode, style: textTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(labelText: l10n.inviteCodeLabel),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _act(() async {
                        await widget.boards.joinByCode(_code.text);
                        _code.clear();
                      }),
                child: Text(l10n.joinLabel),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(l10n.createCommunity, style: textTheme.titleMedium),
          TextField(
            controller: _newName,
            maxLength: 60,
            decoration: InputDecoration(labelText: l10n.communityName),
            onChanged: (_) => setState(() {}),
          ),
          RadioGroup<bool>(
            groupValue: _group,
            onChanged: (v) => setState(() => _group = v ?? false),
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.communityKindRegion),
                ),
                RadioListTile<bool>(
                  value: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.communityKindGroup),
                ),
              ],
            ),
          ),
          if (_group)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _private,
              onChanged: (v) => setState(() => _private = v ?? false),
              title: Text(l10n.communityPrivate),
            ),
          FilledButton(
            onPressed: _busy || (cleanName(_newName.text)?.length ?? 0) < 3
                ? null
                : () => _act(() async {
                    await widget.boards.create(
                      _newName.text,
                      group: _group,
                      private: _private,
                    );
                    _newName.clear();
                  }),
            child: Text(l10n.createLabel),
          ),
          const Divider(height: 32),
          FutureBuilder<bool>(
            future: _visible,
            builder: (context, snap) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: snap.data ?? true,
              onChanged: snap.hasData
                  ? (v) async {
                      await widget.boards.setVisible(v);
                      setState(() {
                        _visible = Future.value(v);
                      });
                    }
                  : null,
              title: Text(l10n.areaVisible),
              subtitle: Text(l10n.areaVisibleNote),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.entry,
    required this.name,
    required this.value,
    required this.shareTooltip,
    required this.onShare,
  });

  final LeaderboardEntry entry;
  final String name;
  final String value;
  final String shareTooltip;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final medal = switch (entry.rank) {
      1 => Brand.saffron,
      2 => Brand.khaki,
      3 => const Color(0xFFB07A4A),
      _ => null,
    };
    return Card(
      color: entry.isMe ? colors.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: entry.isMe
            ? const BorderSide(color: Brand.saffron, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medal ?? colors.secondaryContainer,
              ),
              child: Text(
                '${entry.rank}',
                style: numerals(26, color: Brand.ink),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value.split(' ').first,
                        style: numerals(30),
                      ),
                      if (value.contains(' '))
                        TextSpan(
                          text: ' ${value.substring(value.indexOf(' ') + 1)}',
                          style: textTheme.titleSmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (onShare != null)
              IconButton(
                tooltip: shareTooltip,
                icon: const Icon(Icons.share),
                onPressed: onShare,
              ),
          ],
        ),
      ),
    );
  }
}
