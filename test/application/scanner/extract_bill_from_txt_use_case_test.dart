import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/scanner/extract_bill_from_txt_use_case.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

Future<File> _tmpFile(String content) async {
  final dir = Directory.systemTemp;
  final file = File(
      '${dir.path}/test_boleto_${DateTime.now().millisecondsSinceEpoch}.txt');
  await file.writeAsString(content);
  return file;
}

void main() {
  final useCase = const ExtractBillFromTxtUseCase();

  group('ExtractBillFromTxtUseCase', () {
    test('extracts barcode from TXT file', () async {
      final file = await _tmpFile(
        '03399000000000000000000000000000099990000015130\n'
        'Vencimento: 19/04/2026\n',
      );
      final result = await useCase.execute(file);
      await file.delete();

      expect(result.hasBarcode, isTrue);
      expect(result.source, ScanSourceType.txt);
    });

    test('extracts amount from TXT file', () async {
      final file =
          await _tmpFile('Valor: R\$ 1.500,00\nVencimento: 30/04/2026');
      final result = await useCase.execute(file);
      await file.delete();

      expect(result.hasAmount, isTrue);
      expect(result.amount!.amount, closeTo(1500.0, 0.01));
    });

    test('returns zero confidence for empty file', () async {
      final file = await _tmpFile('');
      final result = await useCase.execute(file);
      await file.delete();

      expect(result.confidence, equals(0.0));
    });

    test('TXT receives quality boost over raw OCR', () async {
      // TXT: barcode alone → heuristic score 0.55 + boost 0.12 = 0.67
      final file = await _tmpFile(
        '03399000000000000000000000000000099990000015130',
      );
      final result = await useCase.execute(file);
      await file.delete();

      expect(result.confidence, greaterThan(0.55));
    });

    test('source is always ScanSourceType.txt', () async {
      final file = await _tmpFile('R\$ 100,00');
      final result = await useCase.execute(file);
      await file.delete();

      expect(result.source, ScanSourceType.txt);
    });

    test('extracts due date from TXT', () async {
      final file = await _tmpFile('Data de Vencimento: 15/09/2026\nR\$ 300,00');
      final result = await useCase.execute(file);
      await file.delete();

      expect(result.hasDueDate, isTrue);
      expect(result.dueDate!.month, 9);
    });
  });
}
