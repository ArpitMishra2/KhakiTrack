import 'package:flutter_test/flutter_test.dart';

/// Switches to the standards tab (the exam list).
Future<void> openStandards(WidgetTester tester) async {
  await tester.tap(find.text('मानक'));
  await tester.pumpAndSettle();
}
