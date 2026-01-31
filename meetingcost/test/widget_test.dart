import 'package:flutter_test/flutter_test.dart';
import 'package:meetingcost/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MeetingCostApp());
    expect(find.text('MeetingCost'), findsOneWidget);
  });
}
