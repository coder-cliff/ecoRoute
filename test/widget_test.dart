import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/models/waste_category.dart';
import 'package:ecoroute/models/waste_request.dart';
import 'package:ecoroute/widgets/cash_payment_banner.dart';
import 'package:ecoroute/widgets/status_badge.dart';
import 'package:ecoroute/widgets/waste_card.dart';

void main() {
  testWidgets('StatusBadge displays correct text and colors for pending', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: RequestStatus.pending),
        ),
      ),
    );

    expect(find.text('Pending Dispatch'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
  });

  testWidgets('StatusBadge displays correct text for collected', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: RequestStatus.collected),
        ),
      ),
    );

    expect(find.text('Collected & Paid'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('CashPaymentBanner displays hard cash instruction and amount', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CashPaymentBanner(amount: 5.50, isCollected: false),
        ),
      ),
    );

    expect(find.text('Pay With Hard Cash: \$5.50'), findsOneWidget);
    expect(find.textContaining('Please have exact cash ready for the rider'), findsOneWidget);
  });

  testWidgets('WasteCard renders category title, cash due, and address', (WidgetTester tester) async {
    final now = DateTime.now();
    final testReq = WasteRequest(
      id: 'REQ-101',
      userId: 'cit_1',
      userName: 'Alice',
      userPhone: '+256 700 112233',
      photoPath: '',
      categoryType: WasteCategoryType.plastics,
      quantityBags: 2,
      latitude: 0.3340,
      longitude: 32.5686,
      address: 'Plot 42, Jinja Road, Kampala',
      notes: '',
      estimatedCashAmount: 4.00,
      status: RequestStatus.pending,
      createdAt: now,
      scheduledPickupTime: now.add(const Duration(hours: 1)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WasteCard(
            request: testReq,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Plastics & Bottles'), findsOneWidget);
    expect(find.text('Plot 42, Jinja Road, Kampala'), findsOneWidget);
    expect(find.text('Due in Cash: \$4.00'), findsOneWidget);
    expect(find.text('2 bags'), findsOneWidget);
  });
}
