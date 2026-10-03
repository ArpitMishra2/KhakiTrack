import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../l10n/app_localizations.dart';

/// One-tap Hindi/English switch for the top bar. Shows the language you
/// would switch to ("EN" while in Hindi, "हि" while in English). Hidden when
/// the app has no settings to change (some tests).
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.maybeOf(context);
    if (settings == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final next = Localizations.localeOf(context).languageCode == 'hi'
        ? 'en'
        : 'hi';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: l10n.switchLanguage,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => settings.setLanguage(next),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate, size: 16, color: colors.onSurface),
                const SizedBox(width: 6),
                Text(
                  l10n.switchLanguageShort,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
