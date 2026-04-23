import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result from an OCR pass on a single image file.
final class OcrResult {
  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.confidence,
  });

  /// Full concatenated text from all recognised blocks.
  final String fullText;

  /// Individual text blocks in document reading order.
  final List<String> blocks;

  /// Average confidence across all recognised blocks (0.0–1.0).
  /// ML Kit does not expose per-block scores; this is approximated from
  /// block count and text length — callers should treat it as indicative.
  final double confidence;

  bool get hasText => fullText.trim().isNotEmpty;
}

/// Abstraction over the ML Kit text recogniser.
///
/// A fake implementation is used in tests; the real one calls ML Kit on-device.
abstract interface class OcrDatasource {
  Future<OcrResult> recogniseFromFile(File imageFile);
  Future<void> close();
}

/// Production implementation using [TextRecognizer] from ML Kit.
///
/// Privacy note: recognition runs entirely on-device; no data is uploaded.
final class MlKitOcrDatasource implements OcrDatasource {
  MlKitOcrDatasource()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<OcrResult> recogniseFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);

    final blocks = recognized.blocks
        .map((b) => b.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final fullText = recognized.text;
    final confidence = _estimateConfidence(blocks, fullText);

    return OcrResult(
      fullText: fullText,
      blocks: blocks,
      confidence: confidence,
    );
  }

  @override
  Future<void> close() => _recognizer.close();

  /// Approximates confidence from structural signals.
  /// ML Kit Latin recogniser is generally high-quality; we penalise
  /// very short outputs (likely blank/noisy images).
  double _estimateConfidence(List<String> blocks, String fullText) {
    if (fullText.trim().isEmpty) return 0.0;
    final charCount = fullText.replaceAll(RegExp(r'\s+'), '').length;
    if (charCount < 10) return 0.3;
    if (charCount < 50) return 0.6;
    return 0.85;
  }
}
