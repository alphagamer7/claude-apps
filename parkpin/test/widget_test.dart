import 'package:flutter_test/flutter_test.dart';

import 'package:parkpin/main.dart';

void main() {
  testWidgets('ParkPin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkPinApp());
    expect(find.text('ParkPin'), findsOneWidget);
  });
}
