import 'package:mocktail/mocktail.dart';
import 'package:paguei/core/logging/app_logger.dart';
import 'package:paguei/data/database/app_database.dart';

class MockAppLogger extends Mock implements AppLogger {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeFailure extends Fake {}

void registerFallbackValues() {
  registerFallbackValue(FakeFailure());
}
