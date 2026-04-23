import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';

/// Canonical parser for Brazilian boletos.
///
/// Handles both 44-digit barcodes and 47-digit linhas digitáveis. For 47-digit
/// lines, amount and due date come from the canonical FEBRABAN positions, never
/// from surrounding invoice text.
final class BoletoCodeParser {
  const BoletoCodeParser._();

  static final _stripFormatting = RegExp(r'[\s.\-]');
  static final _digitOnly = RegExp(r'^\d+$');

  static final _legacyBaseDate = DateTime(1997, 10, 7);
  static final _newCycleBaseDate = DateTime(2025, 2, 22);

  static const _bankNames = <String, String>{
    '001': 'Banco do Brasil',
    '033': 'Banco Santander',
    '077': 'Banco Inter',
    '104': 'Caixa Econômica Federal',
    '237': 'Banco Bradesco',
    '260': 'Nubank',
    '341': 'Banco Itaú',
    '336': 'Banco C6',
    '422': 'Banco Safra',
    '748': 'Sicredi',
    '756': 'Sicoob',
  };

  static BoletoCodeParseResult? tryParse(String raw) {
    final digits = raw.replaceAll(_stripFormatting, '');
    if (!_digitOnly.hasMatch(digits)) return null;
    if (digits.length != 44 && digits.length != 47) return null;

    if (digits.length == 47) return _parseLinhaDigitavel(digits);
    return _parseBarcode44(digits);
  }

  static BoletoCodeParseResult _parseLinhaDigitavel(String digits) {
    final barcode44 = _linhaDigitavelToBarcode44(digits);
    final mod10Valid = Barcode.validateMod10(digits.substring(0, 10)) &&
        Barcode.validateMod10(digits.substring(10, 21)) &&
        Barcode.validateMod10(digits.substring(21, 32));
    final mod11Valid = _validateBarcode44Mod11(barcode44);

    return BoletoCodeParseResult(
      originalCode: digits,
      barcode44: barcode44,
      linhaDigitavel: digits,
      bankName: _bankNames[digits.substring(0, 3)],
      amount: _amountFromCentavos(digits.substring(37, 47)),
      dueDate: _dueDateFromFactor(digits.substring(33, 37)),
      mod10Valid: mod10Valid,
      mod11Valid: mod11Valid,
    );
  }

  static BoletoCodeParseResult _parseBarcode44(String digits) {
    return BoletoCodeParseResult(
      originalCode: digits,
      barcode44: digits,
      linhaDigitavel: null,
      bankName: _bankNames[digits.substring(0, 3)],
      amount: _amountFromCentavos(digits.substring(9, 19)),
      dueDate: _dueDateFromFactor(digits.substring(5, 9)),
      mod10Valid: true,
      mod11Valid: _validateBarcode44Mod11(digits),
    );
  }

  static String _linhaDigitavelToBarcode44(String digits) {
    final bankAndCurrency = digits.substring(0, 4);
    final freeField = digits.substring(4, 9) +
        digits.substring(10, 20) +
        digits.substring(21, 31);
    final generalCheckDigit = digits.substring(32, 33);
    final dueFactor = digits.substring(33, 37);
    final amount = digits.substring(37, 47);

    return bankAndCurrency + generalCheckDigit + dueFactor + amount + freeField;
  }

  static bool _validateBarcode44Mod11(String digits) {
    final data = digits.substring(0, 4) + digits.substring(5);
    final checkDigit = digits[4];
    return Barcode.validateMod11(data + checkDigit);
  }

  static Money? _amountFromCentavos(String centavos) {
    final cents = int.tryParse(centavos);
    if (cents == null || cents == 0) return null;
    return Money(cents);
  }

  static DateTime? _dueDateFromFactor(String factorStr) {
    final factor = int.tryParse(factorStr);
    if (factor == null || factor == 0) return null;

    // FEBRABAN restarted the due-date factor at 1000 on 22/02/2025.
    // In modern bills, low factors such as 1429 refer to 2026 dates, not 2001.
    if (factor >= 1000 && factor < 3000) {
      return _newCycleBaseDate.add(Duration(days: factor - 1000));
    }

    return _legacyBaseDate.add(Duration(days: factor));
  }
}

final class BoletoCodeParseResult {
  const BoletoCodeParseResult({
    required this.originalCode,
    required this.barcode44,
    required this.mod10Valid,
    required this.mod11Valid,
    this.linhaDigitavel,
    this.bankName,
    this.amount,
    this.dueDate,
  });

  final String originalCode;
  final String barcode44;
  final String? linhaDigitavel;
  final String? bankName;
  final Money? amount;
  final DateTime? dueDate;
  final bool mod10Valid;
  final bool mod11Valid;

  String get preferredCode => linhaDigitavel ?? barcode44;
  bool get hasValidChecksum => mod10Valid && mod11Valid;
  double get confidence => hasValidChecksum ? 0.98 : 0.90;
}
