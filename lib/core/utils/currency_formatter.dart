import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final _format = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final _compactFormat = NumberFormat.compact(locale: 'pt_BR');

  static String format(double amount) => _format.format(amount);

  static String formatCompact(double amount) {
    if (amount.abs() < 1000) return format(amount);
    return 'R\$ ${_compactFormat.format(amount)}';
  }

  static String formatAbsolute(double amount) => _format.format(amount.abs());

  static double? parse(String value) {
    try {
      final cleaned = value
          .replaceAll('R\$', '')
          .replaceAll(RegExp(r'\s'), '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return double.parse(cleaned);
    } on FormatException {
      return null;
    }
  }
}
