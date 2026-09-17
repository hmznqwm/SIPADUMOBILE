import 'package:flutter_test/flutter_test.dart';

import 'package:smart_course_scheduler/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartScheduleApp());
    expect(find.byType(SmartScheduleApp), findsOneWidget);
  });
}
