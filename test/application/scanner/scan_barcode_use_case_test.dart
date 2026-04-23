import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/scanner/scan_barcode_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

void main() {
  late ScanBarcodeUseCase useCase;

  setUp(() => useCase = const ScanBarcodeUseCase());

  // Valid 44-digit boleto barcode (Bradesco test): digits represent bank+product+free+check+factor+amount
  const valid44 = '03399000000000100009062900000000001490510273';

  group('ScanBarcodeUseCase — boleto barcode', () {
    test('valid 44-digit barcode returns parsed data with barcode field', () {
      final result = useCase.execute(
        raw: valid44,
        source: ScanSourceType.camera,
      );

      expect(result.hasBarcode, isTrue);
      expect(result.barcode, isNotNull);
      expect(result.source, ScanSourceType.camera);
    });

    test('valid barcode with dot/space formatting is stripped and accepted',
        () {
      // Formatted: "03399.00000 00000.010000 90629.000000 0 01490510273"
      const formatted = '03399.00000 00000.010000 90629.000000 0 01490510273';
      expect(
        () => useCase.execute(raw: formatted, source: ScanSourceType.camera),
        returnsNormally,
      );
    });

    test('barcode shorter than 44 digits throws ValidationException', () {
      expect(
        () => useCase.execute(raw: '1234567890', source: ScanSourceType.camera),
        throwsA(isA<ValidationException>()),
      );
    });

    test('barcode with wrong length (45 digits) throws ValidationException',
        () {
      expect(
        () => useCase.execute(
          raw: '0' * 45,
          source: ScanSourceType.camera,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('empty string throws ValidationException', () {
      expect(
        () => useCase.execute(raw: '', source: ScanSourceType.camera),
        throwsA(isA<ValidationException>()),
      );
    });

    test('non-digit characters (after stripping formatting) throw', () {
      expect(
        () => useCase.execute(
          raw: 'ABCDEFGHIJK',
          source: ScanSourceType.camera,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('44-digit barcode result has high confidence', () {
      final result = useCase.execute(
        raw: valid44,
        source: ScanSourceType.camera,
      );
      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('extracts canonical data from Equatorial linha digitável', () {
      const linhaDigitavel =
          '34191.09966 07809.482933 85633.150009 6 14290000006912';

      final result = useCase.execute(
        raw: linhaDigitavel,
        source: ScanSourceType.camera,
      );

      expect(result.barcode, '34191099660780948293385633150009614290000006912');
      expect(result.amount?.amount, closeTo(69.12, 0.01));
      expect(result.dueDate, DateTime(2026, 4, 27));
      expect(result.issuer, 'Banco Itaú');
      expect(result.confidence, greaterThanOrEqualTo(0.98));
    });
  });

  group('ScanBarcodeUseCase — PIX QR code', () {
    // Real EMV PIX payload starts with "000201"
    const validPixPayload =
        '00020126580014BR.GOV.BCB.PIX0136123e4567-e12b-12d1-a456-4266554400005204000053039865802BR5913Empresa Teste6009SAO PAULO62070503***6304B14F';
    const dynamicEquatorialPix =
        '00020101021226770014br.gov.bcb.pix2555api.itau/pix/qr/v2/fa875b9c-fd8a-4bba-a1f0-fbaae681769c5204000053039865802BR5916EQUATORIAL GOIAS6007GOIANIA6217051320260358352146304AA0F';

    test('valid PIX EMV payload returns parsed data with pixCode field', () {
      final result = useCase.execute(
        raw: validPixPayload,
        source: ScanSourceType.qrCode,
      );

      expect(result.hasPixCode, isTrue);
      expect(result.pixCode, validPixPayload);
      expect(result.source, ScanSourceType.qrCode);
    });

    test('PIX result has high confidence', () {
      final result = useCase.execute(
        raw: validPixPayload,
        source: ScanSourceType.qrCode,
      );
      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('PIX payload does not populate barcode field', () {
      final result = useCase.execute(
        raw: validPixPayload,
        source: ScanSourceType.qrCode,
      );
      expect(result.hasBarcode, isFalse);
    });

    test('dynamic PIX QR from camera stays in PIX flow, not boleto flow', () {
      final result = useCase.execute(
        raw: dynamicEquatorialPix,
        source: ScanSourceType.qrCode,
      );

      expect(result.hasPixCode, isTrue);
      expect(result.hasBarcode, isFalse);
      expect(result.pixCode, dynamicEquatorialPix);
      expect(result.pixKey, startsWith('https://api.itau/'));
      expect(result.pixLocationUrl, startsWith('https://api.itau/'));
      expect(
        result.pixMerchantName,
        'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
      );
      expect(
        result.beneficiary,
        'EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A',
      );
      expect(result.pixCity, 'GOIANIA');
      expect(result.pixTxId, '2026035835214');
    });

    test('dynamic PIX QR from imported image stays in PIX flow', () {
      final result = useCase.execute(
        raw: dynamicEquatorialPix,
        source: ScanSourceType.image,
      );

      expect(result.hasPixCode, isTrue);
      expect(result.hasBarcode, isFalse);
      expect(result.pixLocationUrl, startsWith('https://api.itau/'));
      expect(result.pixTxId, '2026035835214');
    });

    test('extracts PIX EMV merchant, city, value, key and txid', () {
      const payload =
          '00020126580014BR.GOV.BCB.PIX0136123e4567-e89b-12d3-a456-426655440000520400005303986540569.125802BR5913Empresa Teste6007GOIANIA62140510TX123456786304B14F';

      final result = useCase.execute(
        raw: payload,
        source: ScanSourceType.qrCode,
      );

      expect(result.pixCode, payload);
      expect(result.pixKey, '123e4567-e89b-12d3-a456-426655440000');
      expect(result.pixMerchantName, 'Empresa Teste');
      expect(result.beneficiary, 'Empresa Teste');
      expect(result.pixCity, 'GOIANIA');
      expect(result.pixTxId, 'TX12345678');
      expect(result.amount?.amount, closeTo(69.12, 0.01));
    });

    test('extracts PIX EMV payload embedded in scanned QR text', () {
      const payload =
          '00020126580014BR.GOV.BCB.PIX0136123e4567-e89b-12d3-a456-4266554400005204000053039865802BR5913Empresa Teste6007GOIANIA62140510TX123456786304B14F';

      final result = useCase.execute(
        raw: 'PIX copia e cola:\n$payload',
        source: ScanSourceType.qrCode,
      );

      expect(result.hasPixCode, isTrue);
      expect(result.pixCode, payload);
      expect(result.pixMerchantName, 'Empresa Teste');
    });

    test('short non-EMV text throws ValidationException', () {
      expect(
        () => useCase.execute(raw: 'abc', source: ScanSourceType.qrCode),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ScanBarcodeUseCase — amount extraction from barcode', () {
    // 44-digit barcode: positions 10-19 are the amount in centavos.
    // e.g. "0000000100" = R$ 1,00
    test('extracts amount from canonical amount field of 44-digit barcode', () {
      // Build a 44-digit barcode with amount = 15130 (R$ 151,30)
      // 44-digit: bank(3) + currency(1) + check(1) + dueDate_factor(4) + amount(10) + free_field(25)
      final b44 = '0339199990000015130${'0' * 25}';
      expect(b44.length, 44);

      final result = useCase.execute(raw: b44, source: ScanSourceType.camera);
      expect(result.hasAmount, isTrue);
      expect(result.amount?.amount, closeTo(151.30, 0.01));
    });
  });
}
