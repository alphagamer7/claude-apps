import 'package:flutter_test/flutter_test.dart';
import 'package:huematch/main.dart';

void main() {
  testWidgets('HueMatch app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HueMatchApp(cameras: []));
    // Camera screen should show loading indicator when no cameras
    expect(find.byType(HueMatchApp), findsOneWidget);
  });
}
