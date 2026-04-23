sealed class Failure {
  const Failure({required this.message});

  final String message;
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}

final class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

final class ScanFailure extends Failure {
  const ScanFailure({required super.message, required this.type});

  final ScanFailureType type;
}

enum ScanFailureType {
  cameraPermissionDenied,
  unrecognizedFormat,
  pdfExtractionFailed,
  ocrFailed,
}

final class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, this.stackTrace});

  final StackTrace? stackTrace;
}
