import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/scanner/bill_extraction_heuristics.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Barcode extraction
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — barcode from raw text', () {
    test('extracts 44-digit raw barcode embedded in OCR text', () {
      const text = '''
Banco do Brasil
Agência / Cedente: 1234-5 / Empresa Teste
03399000000000100009062900000000001490510273
Vencimento: 19/04/2026
''';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasBarcode, isTrue);
      expect(result.barcode!.length, 44);
    });

    test('extracts formatted linha digitável from OCR text', () {
      const text = '''
Nosso Número: 12345678
12345.67890 12345.678901 23456.789012 3 45678901234567
Beneficiário: Empresa XYZ Ltda
''';
      // 47 digits after stripping dots and spaces → valid linha digitável
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasBarcode, isTrue);
    });

    test('does NOT confuse 10-digit phone numbers with barcodes', () {
      const text = 'Telefone: 11999887766\nCEP: 01310100';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasBarcode, isFalse);
    });

    test('uses boleto line amount and due date over random invoice values', () {
      const text = '''
RAYLANE DE NORONHA CARDOSO
DATA DE EMISSÃO: 15/04/2026
PERÍODO DE REFERÊNCIA. VRC = R\$ 20,94
CONSUMO SCEE 185,87 19% 35,32
BENEFÍCIO TARIFÁRIO BRUTO SCEE 105,17
TOTAL 69,12
BANCO ITAÚ 34191.09966 07809.482933 85633.150009 6 14290000006912
PAGÁVEL EM QUALQUER BANCO 27/04/2026
EQUATORIAL GOIAS DISTRIBUIDORA DE ENERGIA S/A
CÓDIGO DO PIX:
00020101021226770014br.gov.bcb.pix2555api.itau/pix/qr/v2/fa875b9c-fd8a-4bba-a1f0-fbaae681769c5204000053039865802BR5916EQUATORIAL GOIAS6007GOIANIA6217051320260358352146304AA0F
''';

      final result = BillExtractionHeuristics.extractFromText(
        text,
        source: ScanSourceType.pdf,
      );

      expect(result.hasBarcode, isTrue);
      expect(result.hasPixCode, isTrue);
      expect(result.amount?.amount, closeTo(69.12, 0.01));
      expect(result.dueDate, DateTime(2026, 4, 27));
      expect(result.issuer, 'Banco Itaú');
      expect(result.beneficiary, contains('Equatorial'));
      expect(result.beneficiary, isNot(contains('RAYLANE')));
      expect(result.warnings, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // PIX extraction
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — PIX payload detection', () {
    test('recognises EMV PIX payload in text', () {
      const pixPayload =
          '00020126580014BR.GOV.BCB.PIX0136123e4567-e12b-12d1-a456-'
          '4266554400005204000053039865802BR5913EmpresaTeste6009SAOPAULO'
          '62070503***6304B14F';
      final result = BillExtractionHeuristics.extractFromText(
        'Pague via PIX: $pixPayload\nValor: R\$ 150,00',
        source: ScanSourceType.image,
      );
      expect(result.hasPixCode, isTrue);
      expect(result.pixCode, contains('000201'));
    });

    test('does NOT flag non-EMV text as PIX', () {
      const text = 'Código de acesso: 99887766554433221100';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasPixCode, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Amount extraction
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — amount from OCR text', () {
    test('extracts R\$ formatted amount', () {
      const text = 'Total a pagar: R\$ 1.234,56\nVencimento: 30/04/2026';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasAmount, isTrue);
      expect(result.amount!.amount, closeTo(1234.56, 0.01));
    });

    test('extracts amount without thousand separator', () {
      const text = 'Valor: R\$150,00';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasAmount, isTrue);
      expect(result.amount!.amount, closeTo(150.0, 0.01));
    });

    test('extracts amount labeled "Valor do Documento"', () {
      const text = 'Valor do Documento    R\$ 2.500,00';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasAmount, isTrue);
      expect(result.amount!.amount, closeTo(2500.0, 0.01));
    });

    test('ignores amount of zero', () {
      const text = 'Valor: R\$ 0,00';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasAmount, isFalse);
    });

    test('returns null when no amount present', () {
      const text = 'Empresa Teste CNPJ 12.345.678/0001-99';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasAmount, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Date extraction
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — due date from OCR text', () {
    test('extracts date labelled "Vencimento"', () {
      const text = 'Vencimento: 19/04/2026\nValor: R\$ 300,00';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasDueDate, isTrue);
      expect(result.dueDate!.year, 2026);
      expect(result.dueDate!.month, 4);
      expect(result.dueDate!.day, 19);
    });

    test('extracts date labelled "Data de Vencimento"', () {
      const text = 'Data de Vencimento: 01/06/2026';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasDueDate, isTrue);
      expect(result.dueDate!.month, 6);
    });

    test('falls back to first dd/mm/yyyy date in text when no label', () {
      const text = 'Emissão 05/03/2026\nVence 30/04/2026\nR\$ 99,90';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasDueDate, isTrue);
    });

    test('does not extract invalid calendar dates', () {
      const text = 'Data: 32/13/2026';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.hasDueDate, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Beneficiary extraction
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — beneficiary from OCR text', () {
    test('extracts beneficiary after "Beneficiário:"', () {
      const text = 'Beneficiário: Empresa ABC Ltda\nCNPJ: 12.345.678/0001-99';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.beneficiary, contains('Empresa ABC Ltda'));
    });

    test('extracts beneficiary after "Cedente:"', () {
      const text = 'Cedente: Banco do Brasil S.A.';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.beneficiary, isNotNull);
    });

    test('returns null when no beneficiary label present', () {
      const text = 'Valor: R\$ 100,00\nVencimento: 30/04/2026';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.beneficiary, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Confidence scoring
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — confidence scoring', () {
    test('barcode + amount + date → high confidence', () {
      const text = '''
03399000000000100009062900000000001490510273
Vencimento: 19/04/2026
Valor: R\$ 151,30
Beneficiário: Empresa Teste
''';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('only amount → low confidence', () {
      const text = 'Valor: R\$ 100,00';
      final result = BillExtractionHeuristics.extractFromText(text,
          source: ScanSourceType.image);
      expect(result.confidence, lessThan(0.85));
    });

    test('empty text → zero confidence', () {
      final result = BillExtractionHeuristics.extractFromText('',
          source: ScanSourceType.image);
      expect(result.confidence, equals(0.0));
    });
  });

  // ---------------------------------------------------------------------------
  // Source type preserved
  // ---------------------------------------------------------------------------

  group('BillExtractionHeuristics — source type', () {
    test('preserves source type from caller', () {
      final result = BillExtractionHeuristics.extractFromText(
        'R\$ 100,00',
        source: ScanSourceType.pdf,
      );
      expect(result.source, ScanSourceType.pdf);
    });
  });
}
