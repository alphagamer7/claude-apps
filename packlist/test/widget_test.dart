import 'package:flutter_test/flutter_test.dart';

import 'package:packlist/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const PackListApp());
    expect(find.text('PackList'), findsOneWidget);
  });
}
