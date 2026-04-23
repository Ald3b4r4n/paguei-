import 'package:paguei/domain/repositories/account_repository.dart';

final class DeactivateAccountUseCase {
  const DeactivateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> archive(String id) => _repository.archive(id);

  Future<void> unarchive(String id) => _repository.unarchive(id);
}
