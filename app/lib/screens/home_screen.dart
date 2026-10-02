import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.welcomeTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.welcomeSubtitle),
            const SizedBox(height: 24),
            Text(l10n.chooseExam,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(child: ListTile(title: Text(l10n.examUpPolice))),
            Card(child: ListTile(title: Text(l10n.examSscGd))),
          ],
        ),
      ),
    );
  }
}
