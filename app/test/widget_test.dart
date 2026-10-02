import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/main.dart';

void main() {
  testWidgets('home screen is Hindi by default', (tester) async {
    await tester.pumpWidget(const MaidanApp());
    await tester.pumpAndSettle();
    expect(find.text('यूपी पुलिस कांस्टेबल'), findsOneWidget);
    expect(find.text('SSC GD'), findsOneWidget);
  });
}
