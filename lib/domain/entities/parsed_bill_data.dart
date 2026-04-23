import 'package:paguei/domain/entities/scan_source_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

/// Structured data extracted from a boleto scan or OCR pass.
///
/// [confidence] ranges from 0.0 (no data) to 1.0 (verified, high-certainty).
/// Screens use [isHighConfidence] to decide whether to skip the review step.
final class ParsedBillData {
  const ParsedBillData({
    required this.source,
    required this.confidence,
    this.barcode,
    this.pixCode,
    this.amount,
    this.dueDate,
    this.beneficiary,
    this.issuer,
    this.pixKey,
    this.pixLocationUrl,
    this.pixMerchantName,
    this.pixCity,
    this.pixTxId,
    this.rawText,
    this.warnings = const [],
  });

  final ScanSourceType source;
  final double confidence;

  final String? barcode;
  final String? pixCode;
  final Money? amount;
  final DateTime? dueDate;
  final String? beneficiary;
  final String? issuer;
  final String? pixKey;
  final String? pixLocationUrl;
  final String? pixMerchantName;
  final String? pixCity;
  final String? pixTxId;
  final String? rawText;
  final List<String> warnings;

  bool get hasBarcode => barcode != null;
  bool get hasPixCode => pixCode != null;
  bool get hasAmount => amount != null;
  bool get hasDueDate => dueDate != null;

  /// Confidence threshold for skipping the manual review step.
  bool get isHighConfidence => confidence >= 0.85;

  ParsedBillData copyWith({
    ScanSourceType? source,
    double? confidence,
    String? barcode,
    String? pixCode,
    Money? amount,
    DateTime? dueDate,
    String? beneficiary,
    String? issuer,
    String? pixKey,
    String? pixLocationUrl,
    String? pixMerchantName,
    String? pixCity,
    String? pixTxId,
    String? rawText,
    List<String>? warnings,
  }) {
    return ParsedBillData(
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      barcode: barcode ?? this.barcode,
      pixCode: pixCode ?? this.pixCode,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      beneficiary: beneficiary ?? this.beneficiary,
      issuer: issuer ?? this.issuer,
      pixKey: pixKey ?? this.pixKey,
      pixLocationUrl: pixLocationUrl ?? this.pixLocationUrl,
      pixMerchantName: pixMerchantName ?? this.pixMerchantName,
      pixCity: pixCity ?? this.pixCity,
      pixTxId: pixTxId ?? this.pixTxId,
      rawText: rawText ?? this.rawText,
      warnings: warnings ?? this.warnings,
    );
  }

  @override
  String toString() =>
      'ParsedBillData(source: $source, confidence: ${confidence.toStringAsFixed(2)}, '
      'barcode: ${barcode != null}, pix: ${pixCode != null}, amount: $amount, '
      'merchant: $pixMerchantName, pixLocation: ${pixLocationUrl != null}, '
      'warnings: ${warnings.length})';
}
