import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/failures.dart';

void main() {
  group('Failure hierarchy', () {
    test('DatabaseFailure has correct message', () {
      const failure = DatabaseFailure(message: 'db error');
      expect(failure.message, equals('db error'));
      expect(failure, isA<Failure>());
    });

    test('ValidationFailure has correct message', () {
      const failure = ValidationFailure(message: 'campo obrigatório');
      expect(failure.message, equals('campo obrigatório'));
    });

    test('NotFoundFailure has correct message', () {
      const failure = NotFoundFailure(message: 'boleto não encontrado');
      expect(failure.message, equals('boleto não encontrado'));
    });

    test('PermissionFailure has correct message', () {
      const failure = PermissionFailure(message: 'câmera negada');
      expect(failure.message, equals('câmera negada'));
    });

    test('ScanFailure carries type and message', () {
      const failure = ScanFailure(
        message: 'formato não reconhecido',
        type: ScanFailureType.unrecognizedFormat,
      );
      expect(failure.type, equals(ScanFailureType.unrecognizedFormat));
    });

    test('UnexpectedFailure accepts optional stackTrace', () {
      const failure = UnexpectedFailure(message: 'erro inesperado');
      expect(failure.stackTrace, isNull);

      final trace = StackTrace.current;
      final withTrace = UnexpectedFailure(message: 'erro', stackTrace: trace);
      expect(withTrace.stackTrace, equals(trace));
    });

    test('UnexpectedFailure can be instantiated directly', () {
      const failure = UnexpectedFailure(message: 'test');
      expect(failure.message, equals('test'));
      expect(failure, isA<Failure>());
    });

    test('Pattern matching works on all subtypes', () {
      final failures = <Failure>[
        const DatabaseFailure(message: 'db'),
        const ValidationFailure(message: 'val'),
        const NotFoundFailure(message: 'nf'),
        const PermissionFailure(message: 'perm'),
        const ScanFailure(
          message: 'scan',
          type: ScanFailureType.ocrFailed,
        ),
        const StorageFailure(message: 'storage'),
        const NetworkFailure(message: 'net'),
        const UnexpectedFailure(message: 'unex'),
      ];

      for (final f in failures) {
        final result = switch (f) {
          DatabaseFailure() => 'database',
          ValidationFailure() => 'validation',
          NotFoundFailure() => 'not_found',
          PermissionFailure() => 'permission',
          ScanFailure() => 'scan',
          StorageFailure() => 'storage',
          NetworkFailure() => 'network',
          UnexpectedFailure() => 'unexpected',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
