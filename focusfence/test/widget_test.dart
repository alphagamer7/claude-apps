import 'package:flutter_test/flutter_test.dart';
import 'package:focusfence/main.dart';

void main() {
  testWidgets('FocusFence app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusFenceApp());
    expect(find.text('FocusFence'), findsOneWidget);
    expect(find.text('Start Focus Session'), findsOneWidget);
  });
}
