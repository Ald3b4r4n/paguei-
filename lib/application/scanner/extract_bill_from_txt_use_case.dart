import 'dart:io';

import 'package:paguei/application/scanner/bill_extraction_heuristics.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

/// Reads a plain-text file (.txt) and passes the content through
/// [BillExtractionHeuristics] to produce [ParsedBillData].
///
/// TXT files exported from online banking portals often contain a raw
/// 44-digit barcode on its own line — this use case handles that case well.
final class ExtractBillFromTxtUseCase {
  const ExtractBillFromTxtUseCase();

  Future<ParsedBillData> execute(File txtFile) async {
    final text = await txtFile.readAsString();

    if (text.trim().isEmpty) {
      return ParsedBillData(
        source: ScanSourceType.txt,
        confidence: 0.0,
        rawText: '',
      );
    }

    // TXT content is already machine-readable — apply a quality boost similar
    // to PDF (no OCR noise).
    const txtQualityBoost = 0.12;

    final parsed = BillExtractionHeuristics.extractFromText(
      text,
      source: ScanSourceType.txt,
    );

    final boosted = (parsed.confidence + txtQualityBoost).clamp(0.0, 1.0);
    return parsed.copyWith(confidence: boosted);
  }
}
