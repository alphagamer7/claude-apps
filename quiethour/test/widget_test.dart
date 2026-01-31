import 'package:flutter_test/flutter_test.dart';
import 'package:quiethour/main.dart';

void main() {
  testWidgets('QuietHour app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuietHourApp());
    await tester.pumpAndSettle();

    expect(find.text('QuietHour'), findsOneWidget);
    expect(find.text('Quick Activate'), findsOneWidget);
  });
}
