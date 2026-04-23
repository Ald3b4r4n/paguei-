import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static DateFormat _buildFormat(String pattern) {
    try {
      return DateFormat(pattern, 'pt_BR');
    } catch (_) {
      return DateFormat(pattern, 'en_US');
    }
  }

  static final _shortFormat = _buildFormat('dd/MM/yyyy');
  static final _longFormat = _buildFormat("dd 'de' MMMM 'de' yyyy");
  static final _monthYearFormat = _buildFormat('MMMM yyyy');
  static final _shortMonthFormat = _buildFormat('MMM/yy');

  static String formatShort(DateTime date) => _shortFormat.format(date);

  static String formatLong(DateTime date) => _longFormat.format(date);

  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  static String formatShortMonth(DateTime date) =>
      _shortMonthFormat.format(date);

  static String formatDueDate(DateTime dueDate) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    final d = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final t = DateTime(today.year, today.month, today.day);
    final tom = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final yes = DateTime(yesterday.year, yesterday.month, yesterday.day);

    if (d == t) return 'Vence hoje';
    if (d == tom) return 'Vence amanhã';
    if (d == yes) return 'Venceu ontem';
    if (d.isBefore(t)) return 'Venceu em ${_shortFormat.format(dueDate)}';
    return 'Vence em ${_shortFormat.format(dueDate)}';
  }

  static int daysUntilDue(DateTime dueDate) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  static DateTime? parseShort(String value) {
    try {
      return _shortFormat.parse(value);
    } on FormatException {
      return null;
    }
  }
}
