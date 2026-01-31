import 'package:flutter_test/flutter_test.dart';
import 'package:coinflop/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CoinFlopApp());
    expect(find.text('CoinFlop'), findsOneWidget);
    expect(find.text('Pick your randomizer!'), findsOneWidget);
  });
}
