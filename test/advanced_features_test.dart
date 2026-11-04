import 'dart:typed_data';

import 'package:ecoroute/core/services/language_service.dart';
import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/features/payment/momo_payment_dialog.dart';
import 'package:ecoroute/features/request/widgets/waste_camera_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeLocationService extends LocationService {
  const _FakeLocationService();

  @override
  Future<UserLocationResult> getCurrentUserLocation() async {
    return evaluateCoordinates(3.0300, 30.9100);
  }
}

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.fileToReturn});

  final XFile? fileToReturn;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return fileToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageService (Multilingual Support)', () {
    test('translates strings across English, Lugbara, and Swahili', () {
      final lang = LanguageService.instance;

      lang.setLanguage(AppLanguage.english);
      expect(lang.translate('app_title'), 'EcoRoute');
      expect(lang.translate('schedule_pickup'), 'Schedule pickup');
      expect(lang.translate('momo_pay'), 'Pay with Mobile Money');

      lang.setLanguage(AppLanguage.lugbara);
      expect(lang.translate('schedule_pickup'), 'Liru omba');
      expect(lang.translate('move_closer'), 'Mi tu aza liru ci ru...');
      expect(lang.translate('momo_pay'), 'Momo fesi fesi');

      lang.setLanguage(AppLanguage.swahili);
      expect(lang.translate('schedule_pickup'), 'Panga mkusanyiko');
      expect(lang.translate('move_closer'), 'Sogea karibu na taka...');
      expect(lang.translate('momo_pay'), 'Lipa kwa Pesa ya Simu');

      // Reset back to English
      lang.setLanguage(AppLanguage.english);
    });
  });

  group('WasteCameraScanner (Proximity Guidance & Auto-GPS)', () {
    testWidgets('renders camera viewfinder and manual capture controls', (
      WidgetTester tester,
    ) async {
      const locationService = _FakeLocationService();
      WastePhotoCaptureResult? capturedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WasteCameraScanner(
              locationService: locationService,
              onCaptured: (result) => capturedResult = result,
            ),
          ),
        ),
      );

      // Verify guidance prompt and capture controls
      expect(find.text('Rubbish Photo Capture'), findsOneWidget);
      expect(find.text('Manual Camera Capture'), findsOneWidget);
      expect(find.text('Open Camera'), findsOneWidget);
      expect(find.text('From Gallery'), findsOneWidget);

      // Tap manual capture shutter icon
      await tester.tap(find.byIcon(Icons.check_circle_outline_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm and save captured photo
      expect(find.text('Rubbish Photo Verified'), findsOneWidget);
      expect(find.text('Confirm & Save'), findsOneWidget);
      await tester.tap(find.text('Confirm & Save'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, isNotNull);
      expect(capturedResult!.imageLabel, contains('waste_photo'));
      expect(capturedResult!.locationResult.isWithinServiceArea, isTrue);
    });

    testWidgets('displays device camera and gallery action buttons', (
      WidgetTester tester,
    ) async {
      const locationService = _FakeLocationService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WasteCameraScanner(
              locationService: locationService,
              onCaptured: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.photo_library_outlined), findsWidgets);
      expect(find.byIcon(Icons.photo_camera_rounded), findsWidgets);
    });

    testWidgets(
      'automatically launches camera and returns photo evidence when autoLaunchCamera is true',
      (WidgetTester tester) async {
        const locationService = _FakeLocationService();
        WastePhotoCaptureResult? capturedResult;
        final fakePicker = _FakeImagePicker(
          fileToReturn: XFile.fromData(
            Uint8List.fromList([1, 2, 3, 4]),
            name: 'test_evidence.jpg',
            path: 'test_evidence.jpg',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WasteCameraScanner(
                locationService: locationService,
                imagePicker: fakePicker,
                autoLaunchCamera: true,
                onCaptured: (result) => capturedResult = result,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.text('Rubbish Photo Verified'), findsOneWidget);
        expect(find.text('Captured with live device camera'), findsOneWidget);
        expect(find.text('Confirm & Save'), findsOneWidget);

        await tester.tap(find.text('Confirm & Save'));
        await tester.pump();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.imageLabel, 'test_evidence.jpg');
        expect(capturedResult!.photoBytes, isNotNull);
        expect(capturedResult!.locationResult.isWithinServiceArea, isTrue);
      },
    );
  });

  group('MoMoPaymentDialog (Mobile Money & Digital Receipt)', () {
    testWidgets('processes MTN MoMo payment and renders audit receipt with default phone', (
      WidgetTester tester,
    ) async {
      final request = PickupRequest(
        id: 'ord-momo-1',
        wasteType: WasteType.household,
        description: '3 sacks at River Oli compound',
        submittedAt: DateTime(2026, 10, 22),
        status: RequestStatus.awaitingVerification,
        sackCount: 3,
        priceUgx: 4500,
        zone: Zone.west,
        address: 'River Oli, Arua',
        residentPhone: '+256394880352',
      );

      PickupRequest? paidResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoMoPaymentDialog(
              request: request,
              initialPhone: '+256394880352',
              onPaymentSuccess: (updated) async {
                paidResult = updated;
              },
            ),
          ),
        ),
      );

      // Check MTN MoMo is selected and phone is prefilled
      expect(find.text('Mobile Money Payment'), findsOneWidget);
      expect(find.text('+256394880352'), findsOneWidget);
      expect(find.text('Pay 4,500 UGX'), findsOneWidget);

      // Simulate tapping payment
      await tester.tap(find.text('Pay 4,500 UGX'));
      await tester.pump(); // Enter step 1: USSD prompt
      expect(find.text('Sending USSD Prompt...'), findsOneWidget);

      // Advance simulated network delay
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Check step 2: Digital Receipt
      expect(find.text('Payment Completed!'), findsOneWidget);
      expect(find.text('Digital Collection Receipt'), findsOneWidget);
      expect(find.text('Arua EcoRoute Municipal Service'), findsOneWidget);
      expect(find.text('Done & Close Receipt'), findsOneWidget);

      expect(paidResult, isNotNull);
      expect(paidResult!.status, RequestStatus.paid);
      expect(paidResult!.residentPhone, '+256394880352');
    });
  });
}
