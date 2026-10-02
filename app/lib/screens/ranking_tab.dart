import 'package:flutter/material.dart';

import '../data/leaderboard_repository.dart';
import '../data/training_logic.dart';
import '../l10n/app_localizations.dart';
import 'load_error.dart';

/// Weekly leaderboards for the user's village, block, district and state.
class RankingTab extends StatefulWidget {
  const RankingTab({super.key, required this.boards});

  final LeaderboardRepository boards;

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  late Future<Area> _area = widget.boards.myArea();
  String _scope = 'district';
  String _metric = 'pet';
  int _week = 0;
  Future<List<LeaderboardEntry>>? _entries;

  void _load(Area area) {
    final needsBlock =
        (_scope == 'block' && area.block == null) ||
        (_scope == 'village' && (area.block == null || area.village == null));
    _entries = needsBlock
        ? null
        : widget.boards.fetch(_scope, _metric, weekOffset: _week);
  }

  Future<void> _editArea(Area current) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AreaScreen(boards: widget.boards, initial: current),
      ),
    );
    if (saved == true) {
      setState(() {
        _area = widget.boards.myArea();
        _entries = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Area>(
      future: _area,
      builder: (context, snapshot) {
        final area = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tabRanking),
            actions: [
              if (area != null && area.hasDistrict)
                IconButton(
                  tooltip: l10n.editArea,
                  icon: const Icon(Icons.edit_location_alt),
                  onPressed: () => _editArea(area),
                ),
            ],
          ),
          body: snapshot.hasError
              ? Center(
                  child: LoadError(
                    onRetry: () => setState(() {
                      _area = widget.boards.myArea();
                    }),
                  ),
                )
              : area == null
              ? const Center(child: CircularProgressIndicator())
              : !area.hasDistrict
              ? _AreaPrompt(onSet: () => _editArea(area))
              : _boards(context, l10n, area),
        );
      },
    );
  }

  Widget _boards(BuildContext context, AppLocalizations l10n, Area area) {
    if (_entries == null) _load(area);
    final textTheme = Theme.of(context).textTheme;
    void change(VoidCallback f) => setState(() {
      f();
      _load(area);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'village', label: Text(l10n.scopeVillage)),
              ButtonSegment(value: 'block', label: Text(l10n.scopeBlock)),
              ButtonSegment(value: 'district', label: Text(l10n.scopeDistrict)),
              ButtonSegment(value: 'state', label: Text(l10n.scopeState)),
            ],
            selected: {_scope},
            onSelectionChanged: (s) => change(() => _scope = s.first),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.metricPet),
              selected: _metric == 'pet',
              onSelected: (_) => change(() => _metric = 'pet'),
            ),
            ChoiceChip(
              label: Text(l10n.metricDistance),
              selected: _metric == 'distance',
              onSelected: (_) => change(() => _metric = 'distance'),
            ),
            ChoiceChip(
              label: Text(l10n.thisWeek),
              selected: _week == 0,
              onSelected: (_) => change(() => _week = 0),
            ),
            ChoiceChip(
              label: Text(l10n.lastWeek),
              selected: _week == 1,
              onSelected: (_) => change(() => _week = 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.rankingRules, style: textTheme.bodySmall),
        const SizedBox(height: 8),
        if (_entries == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(l10n.rankingNeedsBlock, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => _editArea(area),
                  child: Text(l10n.editArea),
                ),
              ],
            ),
          )
        else
          FutureBuilder<List<LeaderboardEntry>>(
            future: _entries,
            builder: (context, snap) {
              if (snap.hasError) {
                return LoadError(onRetry: () => change(() {}));
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
    );
  }
}

class _AreaPrompt extends StatelessWidget {
  const _AreaPrompt({required this.onSet});

  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.leaderboard, size: 56),
          const SizedBox(height: 16),
          Text(l10n.areaIntro, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onSet, child: Text(l10n.areaTitle)),
        ],
      ),
    );
  }
}

/// Pick district (from the list) and type block and village.
class AreaScreen extends StatefulWidget {
  const AreaScreen({super.key, required this.boards, required this.initial});

  final LeaderboardRepository boards;
  final Area initial;

  @override
  State<AreaScreen> createState() => _AreaScreenState();
}

class _AreaScreenState extends State<AreaScreen> {
  late final Future<List<District>> _districts = widget.boards.districts();
  late String? _district = widget.initial.district;
  late final _block = TextEditingController(text: widget.initial.block ?? '');
  late final _village = TextEditingController(
    text: widget.initial.village ?? '',
  );
  late bool _visible = widget.initial.visible;
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _block.dispose();
    _village.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.boards.saveArea(
        Area(
          district: _district,
          block: _block.text,
          village: _village.text,
          visible: _visible,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.areaTitle)),
      body: FutureBuilder<List<District>>(
        future: _districts,
        builder: (context, snap) {
          final list = snap.data;
          if (snap.hasError) {
            return Center(child: Text(l10n.loadError));
          }
          if (list == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.areaIntro),
              const SizedBox(height: 16),
              DropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                enableFilter: true,
                requestFocusOnTap: true,
                menuHeight: 320,
                initialSelection: _district,
                label: Text(l10n.areaDistrict),
                hintText: l10n.areaChooseDistrict,
                dropdownMenuEntries: [
                  for (final d in list)
                    DropdownMenuEntry(value: d.id, label: d.nameFor(language)),
                ],
                onSelected: (v) => setState(() => _district = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _block,
                decoration: InputDecoration(labelText: l10n.areaBlock),
              ),
              TextField(
                controller: _village,
                decoration: InputDecoration(labelText: l10n.areaVillage),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.areaSpellingHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _visible,
                onChanged: (v) => setState(() => _visible = v),
                title: Text(l10n.areaVisible),
                subtitle: Text(l10n.areaVisibleNote),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _district == null || _saving ? null : _save,
                child: Text(l10n.save),
              ),
              if (_failed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.saveFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
