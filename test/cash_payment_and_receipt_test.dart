import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/features/payment/digital_receipt_dialog.dart';
import 'package:ecoroute/features/payment/momo_payment_dialog.dart';
import 'package:ecoroute/features/rider/widgets/active_trip_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleRequest = PickupRequest(
    id: 'req-cash-test-01',
    wasteType: WasteType.household,
    description: '3 sacks of sorted recyclables at Muni compound',
    submittedAt: DateTime(2026, 10, 29, 10, 30),
    status: RequestStatus.requested,
    sackCount: 3,
    priceUgx: 4500,
    zone: Zone.south,
    address: 'Muni University Staff Quarters, Arua',
    residentName: 'Ayiko Gift',
    residentPhone: '+256 774 224 467',
  );

  group('EcoRoute Hard Cash & Digital Receipt System', () {
    testWidgets('MoMoPaymentDialog switches to Hard Cash and creates cash commitment with digital receipt', (
      WidgetTester tester,
    ) async {
      PickupRequest? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoMoPaymentDialog(
              request: sampleRequest,
              initialPhone: '+256394880352',
              onPaymentSuccess: (updated) async {
                result = updated;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check default view has both channels
      expect(find.text('Mobile Money'), findsOneWidget);
      expect(find.text('Hard Cash to Rider'), findsOneWidget);
      expect(find.text('Free Collection Account: +256 394 880 352'), findsOneWidget);

      // Switch to Hard Cash to Rider
      await tester.tap(find.text('Hard Cash to Rider'));
      await tester.pumpAndSettle();

      expect(find.text('Cash Payment at Gate Handover'), findsOneWidget);
      expect(find.text('Accept & Pay 4,500 UGX Cash at Gate'), findsOneWidget);

      // Confirm cash payment
      await tester.tap(find.text('Accept & Pay 4,500 UGX Cash at Gate'));
      await tester.pumpAndSettle();

      // Receipt step
      expect(find.text('Payment Completed!'), findsOneWidget);
      expect(find.text('Digital Collection Receipt'), findsOneWidget);
      expect(find.text('Hard Cash to Rider (Gate Handover)'), findsOneWidget);
      expect(find.text('CASH PAYMENT ACCEPTED • ECOROUTE'), findsOneWidget);
      expect(find.text('Copy Receipt'), findsOneWidget);
      expect(find.text('Done & Close Receipt'), findsOneWidget);

      expect(result, isNotNull);
      expect(result!.paymentMethod, 'cash');
      expect(result!.cashReceivedByRider, isFalse);
      expect(result!.receiptNumber, isNotNull);
    });

    testWidgets('ActiveTripSheet provides rider on-site Cash Confirmation button and opens receipt', (
      WidgetTester tester,
    ) async {
      final cashPendingStop = sampleRequest.copyWith(
        paymentMethod: 'cash',
        cashReceivedByRider: false,
      );

      PickupRequest? cashConfirmedRequest;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveTripSheet(
              stops: [cashPendingStop],
              initialIndex: 0,
              onAdvanceOrder: (req, status) async {},
              onUpdateSackCount: (req, count, price) async {},
              onUpdateCashReceived: (req) async {
                cashConfirmedRequest = req;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cashHeader = find.text('Cash Collection at Gate');
      await tester.scrollUntilVisible(cashHeader, 300.0, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(cashHeader, findsOneWidget);
      expect(find.text('Confirm Cash Received (4,500 UGX)'), findsOneWidget);

      await tester.tap(find.text('Confirm Cash Received (4,500 UGX)'));
      await tester.pumpAndSettle();

      expect(cashConfirmedRequest, isNotNull);
      expect(cashConfirmedRequest!.cashReceivedByRider, isTrue);
      expect(cashConfirmedRequest!.paymentMethod, 'cash');

      // DigitalReceiptDialog is displayed
      expect(find.text('EcoRoute Logistics'), findsOneWidget);
      expect(find.text('Commercial Waste Receipt • Arua Hub'), findsOneWidget);
      expect(find.text('VERIFIED PAYMENT • ECOROUTE PRIVATE LTD'), findsOneWidget);
      expect(find.text('+256 394 880 352'), findsOneWidget);
    });

    testWidgets('DigitalReceiptDialog renders full commercial details and copies to clipboard', (
      WidgetTester tester,
    ) async {
      final paidRequest = sampleRequest.copyWith(
        paymentMethod: 'cash',
        cashReceivedByRider: true,
        receiptNumber: 'REC-2026-ARU-774411',
        paidAt: DateTime(2026, 10, 29, 11, 15),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DigitalReceiptDialog(request: paidRequest),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REC-2026-ARU-774411'), findsOneWidget);
      expect(find.text('Ayiko Gift'), findsOneWidget);
      expect(find.text('+256 774 224 467'), findsOneWidget);
      expect(find.text('4,500 UGX'), findsOneWidget);
      expect(find.text('Copy Receipt'), findsOneWidget);

      await tester.tap(find.text('Copy Receipt'));
      await tester.pump();
      expect(find.text('Receipt details copied to clipboard. Ready to paste or share.'), findsOneWidget);
    });
  });
}
