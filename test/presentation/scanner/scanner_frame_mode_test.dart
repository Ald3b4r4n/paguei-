import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paguei/presentation/scanner/scanner_frame_mode.dart';

void main() {
  const pixPayload =
      '00020101021226770014br.gov.bcb.pix2555api.itau/pix/qr/v2/fa875b9c-fd8a-4bba-a1f0-fbaae681769c5204000053039865802BR5916EQUATORIAL GOIAS6007GOIANIA6217051320260358352146304AA0F';

  group('ScannerFrameMode geometry', () {
    const viewport = Size(390, 780);

    test('QR mode uses a square frame and scan window', () {
      final frame = scannerFrameFor(viewport, ScannerFrameMode.qr);
      final scanWindow = scanWindowForMode(viewport, ScannerFrameMode.qr);

      expect(frame.width, frame.height);
      expect(scanWindow, isNotNull);
      expect(scanWindow!.width, closeTo(scanWindow.height, 0.01));
    });

    test('barcode mode uses a wide horizontal frame and scan window', () {
      final frame = scannerFrameFor(viewport, ScannerFrameMode.barcode);
      final scanWindow = scanWindowForMode(viewport, ScannerFrameMode.barcode);

      expect(frame.width, greaterThan(frame.height * 2));
      expect(scanWindow, isNotNull);
      expect(scanWindow!.width, greaterThan(scanWindow.height * 2));
    });

    test('auto mode does not crop live camera input', () {
      expect(scanWindowForMode(viewport, ScannerFrameMode.auto), isNull);
    });
  });

  group('ScannerFrameMode inference', () {
    test('QR barcode activates QR mode', () {
      const capture = Barcode(
        format: BarcodeFormat.qrCode,
        rawValue: pixPayload,
        size: Size(160, 160),
      );

      expect(inferScannerFrameMode([capture]), ScannerFrameMode.qr);
    });

    test('linear boleto barcode activates barcode mode', () {
      const capture = Barcode(
        format: BarcodeFormat.code128,
        rawValue: '34191099660780948293385633150009614290000006912',
        size: Size(320, 70),
      );

      expect(inferScannerFrameMode([capture]), ScannerFrameMode.barcode);
    });

    test('unknown empty capture keeps auto mode', () {
      expect(inferScannerFrameMode(const []), ScannerFrameMode.auto);
    });
  });

  group('Scanner format regression guard', () {
    test('accepted formats include QR and boleto barcode formats', () {
      expect(acceptedScanFormats, contains(BarcodeFormat.qrCode));
      expect(acceptedScanFormats, contains(BarcodeFormat.code128));
      expect(acceptedScanFormats, contains(BarcodeFormat.itf14));
      expect(acceptedScanFormats, contains(BarcodeFormat.itf2of5));
      expect(acceptedScanFormats, contains(BarcodeFormat.ean13));
      expect(acceptedScanFormats, contains(BarcodeFormat.ean8));
    });

    test('image import decode plan tries QR before barcode', () {
      expect(qrScanFormats, [BarcodeFormat.qrCode]);
      expect(barcodeScanFormats, isNot(contains(BarcodeFormat.qrCode)));
      expect(barcodeScanFormats, contains(BarcodeFormat.code128));
      expect(barcodeScanFormats, contains(BarcodeFormat.itf14));
    });

    test('barcode priority remains above QR when mode is barcode', () {
      const qr = Barcode(
        format: BarcodeFormat.qrCode,
        rawValue: 'QR sem PIX',
        size: Size(120, 120),
      );
      const boleto = Barcode(
        format: BarcodeFormat.code128,
        rawValue: '34191099660780948293385633150009614290000006912',
        size: Size(320, 70),
      );

      final prioritized =
          prioritizeBarcodesForMode([qr, boleto], ScannerFrameMode.barcode);

      expect(prioritized.first.format, BarcodeFormat.code128);
    });

    test('PIX QR priority remains above boleto barcode even in barcode mode',
        () {
      const qr = Barcode(
        format: BarcodeFormat.qrCode,
        rawValue: pixPayload,
        size: Size(160, 160),
      );
      const boleto = Barcode(
        format: BarcodeFormat.code128,
        rawValue: '34191099660780948293385633150009614290000006912',
        size: Size(320, 70),
      );

      final prioritized =
          prioritizeBarcodesForMode([boleto, qr], ScannerFrameMode.barcode);

      expect(prioritized.first.rawValue, pixPayload);
      expect(shouldTreatAsQrPayment(prioritized.first), isTrue);
      expect(inferScannerFrameMode([boleto, qr]), ScannerFrameMode.qr);
    });

    test('boleto barcode is not treated as QR payment', () {
      const boleto = Barcode(
        format: BarcodeFormat.code128,
        rawValue: '34191099660780948293385633150009614290000006912',
        size: Size(320, 70),
      );

      expect(shouldTreatAsQrPayment(boleto), isFalse);
    });
  });
}
