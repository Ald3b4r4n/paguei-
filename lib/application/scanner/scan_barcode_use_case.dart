import 'dart:developer' as developer;

import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/application/scanner/boleto_code_parser.dart';
import 'package:paguei/application/scanner/pix_payload_parser.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

/// Converts a raw scanned string (barcode or QR) into [ParsedBillData].
///
/// Decision tree:
/// 1. If starts with "000201" → EMV PIX payload.
/// 2. If 44 or 47 digits (after stripping) → boleto barcode.
/// 3. Otherwise → throws [ValidationException].
final class ScanBarcodeUseCase {
  const ScanBarcodeUseCase();

  static final _digitOnly = RegExp(r'^\d+$');
  static final _stripFormatting = RegExp(r'[\s.\-]');

  ParsedBillData execute({
    required String raw,
    required ScanSourceType source,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(message: 'Código vazio não é válido.');
    }

    // PIX EMV QR code detection. QR payload gets priority over any other
    // decoder because the scanner can also return text wrappers around it.
    final pixPayload = PixPayloadParser.extractPayload(trimmed);
    if (pixPayload != null) {
      try {
        final pixCode = PixCode(pixPayload);
        final pix = PixPayloadParser.parse(pixPayload);
        developer.log(
          'PIX QR parseado: payloadLength=${pixPayload.length}, '
          'amount=${pix.amount != null}, key=${pix.key != null}, '
          'location=${pix.locationUrl != null}, merchant=${pix.merchantName != null}, '
          'txid=${pix.txId != null}',
          name: 'paguei.scanner.pix',
        );
        return ParsedBillData(
          source: source,
          confidence: 0.97,
          pixCode: pixCode.value,
          amount: pix.amount,
          beneficiary: pix.merchantName,
          pixKey: pix.key ?? pix.locationUrl,
          pixLocationUrl: pix.locationUrl,
          pixMerchantName: pix.merchantName,
          pixCity: pix.city,
          pixTxId: pix.txId,
          rawText: trimmed,
        );
      } on ValidationException {
        rethrow;
      }
    }

    // Boleto barcode (44 or 47 digits).
    final stripped = trimmed.replaceAll(_stripFormatting, '');
    if (!_digitOnly.hasMatch(stripped)) {
      throw const ValidationException(
          message:
              'Código inválido: apenas dígitos, pontos e espaços são aceitos.');
    }

    final barcode = Barcode(stripped); // throws if wrong length
    final parsed = BoletoCodeParser.tryParse(stripped);
    final warnings = <String>[
      if (parsed != null && !parsed.hasValidChecksum)
        'Código lido, mas a validação dos dígitos verificadores falhou.',
    ];

    return ParsedBillData(
      source: source,
      confidence: parsed?.confidence ?? 0.90,
      barcode: barcode.value,
      amount: parsed?.amount,
      dueDate: parsed?.dueDate,
      issuer: parsed?.bankName,
      rawText: trimmed,
      warnings: warnings,
    );
  }
}
