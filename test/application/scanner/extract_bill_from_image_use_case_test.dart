import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/scanner/extract_bill_from_image_use_case.dart';
import 'package:paguei/data/datasources/scanner/ocr_datasource.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

class _FakeOcrDatasource implements OcrDatasource {
  _FakeOcrDatasource(this._text, {this.confidence = 0.85});

  final String _text;
  final double confidence;
  bool closedCalled = false;

  @override
  Future<OcrResult> recogniseFromFile(File imageFile) async {
    return OcrResult(
      fullText: _text,
      blocks: _text.split('\n').where((l) => l.trim().isNotEmpty).toList(),
      confidence: confidence,
    );
  }

  @override
  Future<void> close() async => closedCalled = true;
}

void main() {
  group('ExtractBillFromImageUseCase', () {
    test('extracts boleto barcode from OCR text', () async {
      const text = '''
Banco do Brasil
03399000000000000000000000000000099990000015130
Vencimento: 19/04/2026
Valor: R\$ 151,30
''';
      final useCase = ExtractBillFromImageUseCase(_FakeOcrDatasource(text));
      final result = await useCase.execute(File('fake_path.jpg'));

      expect(result.hasBarcode, isTrue);
      expect(result.source, ScanSourceType.image);
    });

    test('extracts amount from OCR text', () async {
      const text = 'Total a pagar: R\$ 2.345,67\nVencimento: 30/05/2026';
      final useCase = ExtractBillFromImageUseCase(_FakeOcrDatasource(text));
      final result = await useCase.execute(File('fake.jpg'));

      expect(result.hasAmount, isTrue);
      expect(result.amount!.amount, closeTo(2345.67, 0.01));
    });

    test('extracts due date from OCR text', () async {
      const text = 'Vencimento: 15/07/2026\nValor: R\$ 100,00';
      final useCase = ExtractBillFromImageUseCase(_FakeOcrDatasource(text));
      final result = await useCase.execute(File('fake.jpg'));

      expect(result.hasDueDate, isTrue);
      expect(result.dueDate!.day, 15);
      expect(result.dueDate!.month, 7);
    });

    test('returns low confidence for blank image', () async {
      final useCase = ExtractBillFromImageUseCase(
        _FakeOcrDatasource('', confidence: 0.0),
      );
      final result = await useCase.execute(File('blank.jpg'));

      expect(result.confidence, equals(0.0));
    });

    test('blends OCR confidence with heuristic confidence', () async {
      // Good OCR quality but minimal text → moderate final confidence
      final useCase = ExtractBillFromImageUseCase(
        _FakeOcrDatasource('Valor: R\$ 100,00', confidence: 0.85),
      );
      final result = await useCase.execute(File('partial.jpg'));

      // Heuristic score for only amount ≈ 0.20, OCR = 0.85 → blend < 0.85
      expect(result.confidence, lessThan(0.85));
      expect(result.confidence, greaterThan(0.0));
    });

    test('high confidence for barcode + amount + date', () async {
      const text = '''
03399000000000000000000000000000099990000015130
Vencimento: 19/04/2026
Valor: R\$ 151,30
Beneficiário: Empresa Teste Ltda
''';
      final useCase = ExtractBillFromImageUseCase(_FakeOcrDatasource(text));
      final result = await useCase.execute(File('full.jpg'));

      expect(result.confidence, greaterThanOrEqualTo(0.75));
    });

    test('recognises PIX QR payload in image', () async {
      const text = '''
  Pague via PIX:
  00020126580014BR.GOV.BCB.PIX01361234567890123456756789012345678900005204000053039865802BR5913EmpresaTeste6009SAO PAULO62070503***6304B14F
  ''';
      final useCase = ExtractBillFromImageUseCase(_FakeOcrDatasource(text));
      final result = await useCase.execute(File('pix.jpg'));

      expect(result.hasPixCode, isTrue);
    });
  });
}
