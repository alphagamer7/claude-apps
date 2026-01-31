import 'package:flutter_test/flutter_test.dart';

import 'package:snapmeasure/main.dart';

void main() {
  testWidgets('SnapMeasure app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SnapMeasureApp());
    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });
}
