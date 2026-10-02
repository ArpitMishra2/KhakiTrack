import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/auth_service.dart';
import 'package:maidan/main.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';
import 'test_helpers.dart';

void main() {
  Future<FakeAuthService> pumpSignedOut(WidgetTester tester) async {
    final auth = FakeAuthService(signedIn: false);
    await tester.pumpWidget(
      MaidanApp(
        training: FakeTrainingRepository(),
        repository: FakeExamRepository(),
        auth: auth,
        profiles: FakeProfileRepository(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('signed out shows Hindi sign-in, then home after sign-in', (
    tester,
  ) async {
    await pumpSignedOut(tester);
    expect(find.text('Google से जारी रखें'), findsOneWidget);
    expect(find.text('अपनी परीक्षा चुनें'), findsNothing);

    await tester.tap(find.text('Google से जारी रखें'));
    await tester.pumpAndSettle();
    expect(find.text('आपका अपना रनिंग प्लान'), findsOneWidget);
  });

  testWidgets('cancelling the account picker shows no error', (tester) async {
    final auth = await pumpSignedOut(tester);
    auth.nextResult = SignInResult.cancelled;
    await tester.tap(find.text('Google से जारी रखें'));
    await tester.pumpAndSettle();
    expect(find.textContaining('साइन इन नहीं हो सका'), findsNothing);
    expect(find.text('Google से जारी रखें'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows an error and can be retried', (
    tester,
  ) async {
    final auth = await pumpSignedOut(tester);
    auth.nextResult = SignInResult.failed;
    await tester.tap(find.text('Google से जारी रखें'));
    await tester.pumpAndSettle();
    expect(find.textContaining('साइन इन नहीं हो सका'), findsOneWidget);

    auth.nextResult = SignInResult.signedIn;
    await tester.tap(find.text('Google से जारी रखें'));
    await tester.pumpAndSettle();
    expect(find.text('आपका अपना रनिंग प्लान'), findsOneWidget);
  });

  testWidgets('sign out returns to the sign-in screen', (tester) async {
    await tester.pumpWidget(
      MaidanApp(
        training: FakeTrainingRepository(),
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: FakeProfileRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await openStandards(tester);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('Google से जारी रखें'), findsOneWidget);
  });
}
