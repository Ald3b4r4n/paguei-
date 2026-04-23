import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

abstract interface class AppLogger {
  void debug(String message, {Object? context});
  void info(String message, {Object? context});
  void warning(String message, {Object? context});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

final class ConsoleLogger implements AppLogger {
  const ConsoleLogger({this.minimumLevel = LogLevel.debug});

  final LogLevel minimumLevel;

  static const _sensitivePatterns = [
    'password',
    'senha',
    'token',
    'secret',
    'key',
    'cpf',
    'cnpj',
    'barcode',
    'codigo',
    'balance',
    'saldo',
  ];

  @override
  void debug(String message, {Object? context}) {
    if (kReleaseMode) return;
    _log(LogLevel.debug, message, context: context);
  }

  @override
  void info(String message, {Object? context}) =>
      _log(LogLevel.info, message, context: context);

  @override
  void warning(String message, {Object? context}) =>
      _log(LogLevel.warning, message, context: context);

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message);
    if (error != null && !kReleaseMode) {
      debugPrint('[ERROR] Cause: $error');
    }
    if (stackTrace != null && !kReleaseMode) {
      debugPrint('[ERROR] StackTrace:\n$stackTrace');
    }
  }

  void _log(LogLevel level, String message, {Object? context}) {
    if (level.index < minimumLevel.index) return;

    final sanitized = _sanitize(message);
    final prefix = _prefix(level);

    if (kReleaseMode && level == LogLevel.debug) return;

    debugPrint('$prefix $sanitized');
  }

  String _sanitize(String message) {
    var sanitized = message;
    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAll(
        RegExp(pattern, caseSensitive: false),
        '[REDACTED]',
      );
    }
    return sanitized;
  }

  String _prefix(LogLevel level) => switch (level) {
        LogLevel.debug => '[DEBUG]',
        LogLevel.info => '[INFO]',
        LogLevel.warning => '[WARN]',
        LogLevel.error => '[ERROR]',
      };
}
