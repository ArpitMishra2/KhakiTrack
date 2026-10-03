import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/auth_service.dart';
import '../l10n/app_localizations.dart';

/// Language, low-data mode and sign out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = SettingsScope.maybeOf(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.languageLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hi', label: Text('हिन्दी')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {language},
            onSelectionChanged: (s) => settings?.setLanguage(s.first),
          ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.lowDataTitle),
            subtitle: Text(l10n.lowDataNote),
            value: settings?.lowData ?? false,
            onChanged: settings?.setLowData,
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
            onPressed: () => confirmSignOut(context, auth, closeScreen: true),
          ),
        ],
      ),
    );
  }
}

/// Asks first, and says the data is kept: signing out removes nothing.
Future<void> confirmSignOut(
  BuildContext context,
  AuthService auth, {
  bool closeScreen = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final navigator = Navigator.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.signOutConfirmTitle),
      content: Text(l10n.signOutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.signOut),
        ),
      ],
    ),
  );
  if (ok != true) return;
  if (closeScreen) navigator.pop();
  await auth.signOut();
}
