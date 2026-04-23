import 'dart:io';

import 'package:paguei/application/scanner/bill_extraction_heuristics.dart';
import 'package:paguei/data/datasources/scanner/pdf_extractor_datasource.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';

/// Extracts boleto data from a PDF file using Syncfusion text extraction,
/// then routes the raw text through [BillExtractionHeuristics].
final class ExtractBillFromPdfUseCase {
  const ExtractBillFromPdfUseCase(this._pdf);

  final PdfExtractorDatasource _pdf;

  Future<ParsedBillData> execute(File pdfFile) async {
    final extraction = await _pdf.extractText(pdfFile);

    if (!extraction.hasText) {
      return ParsedBillData(
        source: ScanSourceType.pdf,
        confidence: 0.0,
        rawText: '',
      );
    }

    // PDF text is structurally clean (no OCR noise) so we add a fixed boost.
    const pdfQualityBoost = 0.10;

    final parsed = BillExtractionHeuristics.extractFromText(
      extraction.text,
      source: ScanSourceType.pdf,
    );

    final boosted = (parsed.confidence + pdfQualityBoost).clamp(0.0, 1.0);
    return parsed.copyWith(confidence: boosted);
  }
}
