import 'package:flutter/material.dart';

import '../data/heat.dart';
import '../l10n/app_localizations.dart';

/// A warning card in the hot hours of the day; nothing otherwise.
class HeatBanner extends StatelessWidget {
  const HeatBanner({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (!isHeatHour(now)) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.wb_sunny),
        title: Text(AppLocalizations.of(context).heatWarning),
      ),
    );
  }
}
