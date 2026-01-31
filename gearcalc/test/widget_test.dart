import 'package:flutter_test/flutter_test.dart';
import 'package:gearcalc/main.dart';

void main() {
  testWidgets('GearCalc app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const GearCalcApp());
    expect(find.text('GearCalc'), findsOneWidget);
  });
}
