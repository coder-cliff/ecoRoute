import 'package:flutter_test/flutter_test.dart';

import 'package:waste_management/main.dart';

void main() {
  testWidgets('dashboard shows pickup information', (WidgetTester tester) async {
    await tester.pumpWidget(const WasteWiseApp());

    expect(find.text('Good morning, Alex'), findsOneWidget);
    expect(find.text('Tuesday, 24 September'), findsOneWidget);
    expect(find.text('Request extra pickup'), findsOneWidget);
  });

  testWidgets('extra pickup can be requested', (WidgetTester tester) async {
    await tester.pumpWidget(const WasteWiseApp());
    await tester.tap(find.text('Request extra pickup'));
    await tester.pump();

    expect(find.text('Pickup requested'), findsOneWidget);
  });
}
