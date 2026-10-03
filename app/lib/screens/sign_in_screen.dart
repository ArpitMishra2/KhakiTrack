import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final result = await widget.auth.signInWithGoogle();
    // On success the auth gate swaps this screen out.
    if (!mounted || result == SignInResult.signedIn) return;
    setState(() {
      _busy = false;
      _failed = result == SignInResult.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Brand.oliveDeep,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Brand.olive, Brand.oliveDeep],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight - 56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Brand.saffron,
                            ),
                            child: const Icon(
                              Icons.directions_run,
                              size: 56,
                              color: Brand.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l10n.appName,
                          style: textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.welcomeTitle,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.welcomeSubtitle,
                          style: textTheme.bodyLarge?.copyWith(
                            color: Brand.khaki,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 56),
                        FilledButton.icon(
                          onPressed: _busy ? null : _signIn,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(l10n.signInWithGoogle),
                        ),
                        if (_failed) ...[
                          const SizedBox(height: 16),
                          Text(
                            l10n.signInFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          l10n.adultsOnly,
                          style: textTheme.bodySmall?.copyWith(
                            color: Brand.khaki,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
