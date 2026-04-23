class AppException implements Exception {
  const AppException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}

class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.cause});
}

class ValidationException extends AppException {
  const ValidationException({required super.message});
}

class NotFoundException extends AppException {
  const NotFoundException({required super.message});
}

class PermissionException extends AppException {
  const PermissionException({required super.message});
}

class ScanException extends AppException {
  const ScanException({required super.message, super.cause});
}

class StorageException extends AppException {
  const StorageException({required super.message, super.cause});
}
