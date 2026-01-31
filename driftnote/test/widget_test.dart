import 'package:flutter_test/flutter_test.dart';

import 'package:driftnote/main.dart';

void main() {
  testWidgets('DriftNote app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DriftNoteApp());
    expect(find.text('DriftNote'), findsOneWidget);
  });
}
