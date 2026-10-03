import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/widgets.dart';

/// "Demo data" label, shown at the top of a screen while demo mode is on, so
/// nobody mistakes the sample data for real results.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SettingsScope.demoOf(context)) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Pill(
          AppLocalizations.of(context).demoBadge,
          icon: Icons.science,
          background: Brand.saffronSoft,
        ),
      ),
    );
  }
}
