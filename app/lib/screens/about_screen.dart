import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// What the app is, where its numbers come from, what it keeps. Plain facts:
/// this is what a student, a parent or a buyer checks first.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget section(IconData icon, String title, String body) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Brand.khakiSoft,
              ),
              child: Icon(icon, color: Brand.olive, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(
            Icons.verified_outlined,
            l10n.aboutIndependentTitle,
            l10n.aboutIndependent,
          ),
          section(
            Icons.fact_check_outlined,
            l10n.aboutSourcesTitle,
            l10n.aboutSources,
          ),
          section(Icons.lock_outline, l10n.aboutDataTitle, l10n.aboutData),
          section(
            Icons.health_and_safety_outlined,
            l10n.aboutSafetyTitle,
            l10n.aboutSafety,
          ),
        ],
      ),
    );
  }
}
