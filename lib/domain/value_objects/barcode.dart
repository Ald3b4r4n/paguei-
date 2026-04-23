import 'package:paguei/core/errors/exceptions.dart';

/// Represents a validated Brazilian boleto barcode (linha digitável or código de barras).
///
/// Accepts 44-digit (código de barras) or 47-digit (linha digitável) formats after
/// stripping formatting characters (dots, spaces, hyphens).
final class Barcode {
  Barcode._(this._value);

  factory Barcode(String raw) {
    final digits = _stripFormatting(raw);
    if (digits.isEmpty) {
      throw const ValidationException(
          message: 'Código de barras não pode ser vazio.');
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      throw const ValidationException(
          message: 'Código de barras deve conter apenas dígitos.');
    }
    if (digits.length != 44 && digits.length != 47) {
      throw const ValidationException(
        message: 'Código de barras deve ter 44 ou 47 dígitos.',
      );
    }
    return Barcode._(digits);
  }

  final String _value;

  String get value => _value;

  /// Whether this is a 47-digit "linha digitável" format.
  bool get isLinhaDigitavel => _value.length == 47;

  /// Whether this is a 44-digit barcode format.
  bool get isCodigoDeBarras => _value.length == 44;

  static String _stripFormatting(String raw) =>
      raw.replaceAll(RegExp(r'[\s.\-]'), '');

  /// Validates a sequence of digits using mod 10 algorithm.
  /// Used for checking the check digits in "linha digitável".
  static bool validateMod10(String digits) {
    if (digits.length < 2) return false;
    final data = digits.substring(0, digits.length - 1);
    final checkDigit = int.tryParse(digits[digits.length - 1]);
    if (checkDigit == null) return false;

    var sum = 0;
    var multiplier = 2;
    for (var i = data.length - 1; i >= 0; i--) {
      final digit = int.tryParse(data[i]);
      if (digit == null) return false;
      var product = digit * multiplier;
      if (product >= 10) product -= 9;
      sum += product;
      multiplier = multiplier == 2 ? 1 : 2;
    }
    final expected = (10 - (sum % 10)) % 10;
    return checkDigit == expected;
  }

  /// Validates a sequence of digits using mod 11 algorithm.
  /// Used for the overall check digit in 44-digit barcode format.
  static bool validateMod11(String digits) {
    if (digits.length < 2) return false;
    final data = digits.substring(0, digits.length - 1);
    final checkDigit = int.tryParse(digits[digits.length - 1]);
    if (checkDigit == null) return false;

    var sum = 0;
    var multiplier = 2;
    for (var i = data.length - 1; i >= 0; i--) {
      final digit = int.tryParse(data[i]);
      if (digit == null) return false;
      sum += digit * multiplier;
      multiplier = multiplier == 9 ? 2 : multiplier + 1;
    }
    final remainder = sum % 11;
    final expected = (remainder == 0 || remainder == 1) ? 1 : 11 - remainder;
    return checkDigit == expected;
  }

  @override
  bool operator ==(Object other) => other is Barcode && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value;
}
