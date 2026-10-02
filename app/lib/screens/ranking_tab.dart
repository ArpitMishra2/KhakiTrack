import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/leaderboard_repository.dart';
import '../data/training_logic.dart';
import '../l10n/app_localizations.dart';
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
  String _metric = 'pet';
  int _week = 0;
  late Future<List<LeaderboardEntry>> _entries = _fetch();

  Future<List<LeaderboardEntry>> _fetch() =>
      widget.boards.fetch(_community, _metric, weekOffset: _week);

  void _change(VoidCallback f) => setState(() {
    f();
    _entries = _fetch();
  });

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabRanking),
        actions: [
          TextButton.icon(
            onPressed: _manage,
            icon: const Icon(Icons.groups),
            label: Text(l10n.manageCommunities),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<List<Community>>(
            future: _mine,
            builder: (context, snap) {
              final mine = snap.data ?? const <Community>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                          onSelected: (_) => _change(() => _community = c.id),
                        ),
                    ],
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
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 8),
          Text(l10n.rankingRules, style: textTheme.bodySmall),
          const SizedBox(height: 8),
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
                  child: Text(l10n.rankingEmpty, textAlign: TextAlign.center),
                );
              }
              final colors = Theme.of(context).colorScheme;
              return Column(
                children: [
                  for (final e in rows)
                    Card(
                      color: e.isMe ? colors.primaryContainer : null,
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${e.rank}')),
                        title: Text(
                          e.isMe ? '${e.name} (${l10n.youLabel})' : e.name,
                        ),
                        trailing: Text(
                          _metric == 'pet'
                              ? formatDuration(e.value)
                              : l10n.km(e.value.toStringAsFixed(1)),
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
