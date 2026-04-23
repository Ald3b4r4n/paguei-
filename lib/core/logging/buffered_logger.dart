import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Log entry stored in the in-memory ring buffer.
final class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  final LogLevel level;
  final String message;
  final DateTime timestamp;

  String get levelTag => switch (level) {
        LogLevel.debug => 'D',
        LogLevel.info => 'I',
        LogLevel.warning => 'W',
        LogLevel.error => 'E',
      };

  @override
  String toString() =>
      '${timestamp.toLocal().toIso8601String().substring(11, 19)} '
      '[$levelTag] $message';
}

/// [AppLogger] that also keeps the last [capacity] entries in memory.
///
/// Used by the beta diagnostics screen to show a safe, sanitised log
/// tail without requiring adb or a remote logging service.
final class BufferedLogger implements AppLogger {
  BufferedLogger({
    this.capacity = 100,
    this.minimumLevel = LogLevel.debug,
  });

  final int capacity;
  final LogLevel minimumLevel;

  final List<LogEntry> _buffer = [];

  /// The most-recent [capacity] log entries, oldest first.
  List<LogEntry> get entries => List.unmodifiable(_buffer);

  // ── AppLogger interface ──────────────────────────────────────────────────

  @override
  void debug(String message, {Object? context}) {
    if (kReleaseMode) return;
    _add(LogLevel.debug, message);
  }

  @override
  void info(String message, {Object? context}) => _add(LogLevel.info, message);

  @override
  void warning(String message, {Object? context}) =>
      _add(LogLevel.warning, message);

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _add(LogLevel.error, message);
    if (error != null && !kReleaseMode) {
      _add(LogLevel.error, 'cause: $error');
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  void _add(LogLevel level, String message) {
    if (level.index < minimumLevel.index) return;
    final sanitized = _sanitize(message);
    debugPrint('[${_prefix(level)}] $sanitized');
    if (_buffer.length >= capacity) _buffer.removeAt(0);
    _buffer.add(LogEntry(
      level: level,
      message: sanitized,
      timestamp: DateTime.now().toUtc(),
    ));
  }

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

  String _sanitize(String message) {
    var s = message;
    for (final p in _sensitivePatterns) {
      s = s.replaceAll(RegExp(p, caseSensitive: false), '[REDACTED]');
    }
    return s;
  }

  String _prefix(LogLevel level) => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO ',
        LogLevel.warning => 'WARN ',
        LogLevel.error => 'ERROR',
      };
}
