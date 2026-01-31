import 'package:flutter_test/flutter_test.dart';
import 'package:tallymark/main.dart';

void main() {
  testWidgets('TallyMark app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const TallyMarkApp());
    await tester.pumpAndSettle();

    // App should show empty state with "No counters yet"
    expect(find.text('No counters yet'), findsOneWidget);
    expect(find.text('Create Counter'), findsOneWidget);
  });
}
