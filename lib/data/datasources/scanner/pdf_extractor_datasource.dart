import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Result from a PDF text extraction pass.
final class PdfExtractionResult {
  const PdfExtractionResult({
    required this.text,
    required this.pageCount,
  });

  final String text;
  final int pageCount;

  bool get hasText => text.trim().isNotEmpty;
}

abstract interface class PdfExtractorDatasource {
  Future<PdfExtractionResult> extractText(File pdfFile);
}

/// Production implementation using Syncfusion Flutter PDF (community licence).
///
/// Privacy note: extraction runs entirely on-device.
final class SyncfusionPdfExtractorDatasource implements PdfExtractorDatasource {
  const SyncfusionPdfExtractorDatasource();

  @override
  Future<PdfExtractionResult> extractText(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      return PdfExtractionResult(
        text: text,
        pageCount: document.pages.count,
      );
    } finally {
      document.dispose();
    }
  }
}
