import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/scanner/extract_bill_from_pdf_use_case.dart';
import 'package:paguei/data/datasources/scanner/pdf_extractor_datasource.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

class _FakePdfExtractor implements PdfExtractorDatasource {
  _FakePdfExtractor(this._text, {this.pageCount = 1});

  final String _text;
  final int pageCount;

  @override
  Future<PdfExtractionResult> extractText(File pdfFile) async =>
      PdfExtractionResult(text: _text, pageCount: pageCount);
}

void main() {
  group('ExtractBillFromPdfUseCase', () {
    test('extracts amount from PDF text', () async {
      const text = 'Empresa XYZ\nValor: R\$ 789,00\nVencimento: 30/06/2026';
      final useCase = ExtractBillFromPdfUseCase(_FakePdfExtractor(text));
      final result = await useCase.execute(File('invoice.pdf'));

      expect(result.hasAmount, isTrue);
      expect(result.amount!.amount, closeTo(789.0, 0.01));
      expect(result.source, ScanSourceType.pdf);
    });

    test('extracts barcode from PDF text', () async {
      const text = '''
Banco Bradesco
03399000000000000000000000000000099990000015130
Vencimento: 19/04/2026
''';
      final useCase = ExtractBillFromPdfUseCase(_FakePdfExtractor(text));
      final result = await useCase.execute(File('boleto.pdf'));

      expect(result.hasBarcode, isTrue);
    });

    test('extracts due date from PDF text', () async {
      const text = 'Data de Vencimento: 10/08/2026\nR\$ 250,00';
      final useCase = ExtractBillFromPdfUseCase(_FakePdfExtractor(text));
      final result = await useCase.execute(File('bill.pdf'));

      expect(result.hasDueDate, isTrue);
      expect(result.dueDate!.month, 8);
    });

    test('returns zero confidence for empty PDF', () async {
      final useCase = ExtractBillFromPdfUseCase(_FakePdfExtractor(''));
      final result = await useCase.execute(File('empty.pdf'));

      expect(result.confidence, equals(0.0));
    });

    test('source type is always pdf', () async {
      final useCase =
          ExtractBillFromPdfUseCase(_FakePdfExtractor('R\$ 100,00'));
      final result = await useCase.execute(File('doc.pdf'));

      expect(result.source, ScanSourceType.pdf);
    });

    test('PDF parser handles multi-page invoice', () async {
      // Multi-page: second page has the barcode
      const text = '''
Página 1 de 2 — Nota Fiscal
Empresa de Serviços S.A. CNPJ 00.000.000/0001-00

Página 2 de 2 — Boleto de Cobrança
03399000000000000000000000000000099990000078900
Vencimento: 01/07/2026
Valor: R\$ 789,00
''';
      final useCase =
          ExtractBillFromPdfUseCase(_FakePdfExtractor(text, pageCount: 2));
      final result = await useCase.execute(File('multipage.pdf'));

      expect(result.hasBarcode, isTrue);
      expect(result.hasAmount, isTrue);
      expect(result.hasDueDate, isTrue);
    });

    test('extracts benchmark Equatorial boleto PDF with canonical data',
        () async {
      final fixture = File('test/fixtures/2026035835214.pdf');
      expect(fixture.existsSync(), isTrue);

      final useCase = ExtractBillFromPdfUseCase(
        const SyncfusionPdfExtractorDatasource(),
      );
      final result = await useCase.execute(fixture);

      expect(result.barcode, '34191099660780948293385633150009614290000006912');
      expect(result.hasPixCode, isTrue);
      expect(result.amount?.amount, closeTo(69.12, 0.01));
      expect(result.dueDate, DateTime(2026, 4, 27));
      expect(result.issuer, 'Banco Itaú');
      expect(result.beneficiary, contains('Equatorial'));
      expect(result.beneficiary, isNot(contains('RAYLANE')));
      expect(result.confidence, greaterThanOrEqualTo(0.95));
    });
  });
}
