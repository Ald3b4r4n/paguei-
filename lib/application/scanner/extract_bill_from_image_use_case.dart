import 'dart:io';

import 'package:paguei/application/scanner/bill_extraction_heuristics.dart';
import 'package:paguei/data/datasources/scanner/ocr_datasource.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

/// Runs ML Kit OCR on an image file, then applies [BillExtractionHeuristics]
/// to produce structured [ParsedBillData].
///
/// Confidence is the average of the OCR signal quality and the heuristic score,
/// so a high-resolution image with a complete boleto yields ≥ 0.85.
final class ExtractBillFromImageUseCase {
  const ExtractBillFromImageUseCase(this._ocr);

  final OcrDatasource _ocr;

  Future<ParsedBillData> execute(File imageFile) async {
    final ocrResult = await _ocr.recogniseFromFile(imageFile);

    if (!ocrResult.hasText) {
      return ParsedBillData(
        source: ScanSourceType.image,
        confidence: 0.0,
        rawText: '',
      );
    }

    final parsed = BillExtractionHeuristics.extractFromText(
      ocrResult.fullText,
      source: ScanSourceType.image,
    );

    // Blend OCR infrastructure confidence (image quality signal) with
    // heuristic confidence (field extraction signal).
    final blended = (ocrResult.confidence + parsed.confidence) / 2.0;

    return parsed.copyWith(confidence: blended.clamp(0.0, 1.0));
  }
}
