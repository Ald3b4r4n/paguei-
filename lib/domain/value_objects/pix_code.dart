import 'package:paguei/core/errors/exceptions.dart';

/// Represents a validated PIX "Copia e Cola" payment code.
final class PixCode {
  PixCode._(this._value);

  factory PixCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException(
          message: 'Código PIX não pode ser vazio.');
    }
    if (trimmed.length < 10) {
      throw const ValidationException(
        message: 'Código PIX inválido: muito curto.',
      );
    }
    if (trimmed.length > 512) {
      throw const ValidationException(
        message: 'Código PIX inválido: muito longo.',
      );
    }
    return PixCode._(trimmed);
  }

  final String _value;

  String get value => _value;

  /// Whether this looks like an EMV QR code (starts with "000201").
  bool get isEmvQr => _value.startsWith('000201');

  @override
  bool operator ==(Object other) => other is PixCode && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value;
}
