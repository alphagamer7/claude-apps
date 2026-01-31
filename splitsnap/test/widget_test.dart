import 'package:flutter_test/flutter_test.dart';

import 'package:splitsnap/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitSnapApp());
    expect(find.text('SplitSnap'), findsOneWidget);
  });
}
