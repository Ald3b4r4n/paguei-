import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/repositories/account_repository.dart';

final class GetAccountsUseCase {
  const GetAccountsUseCase(this._repository);

  final AccountRepository _repository;

  Future<List<Account>> execute({bool includeArchived = false}) =>
      _repository.getAll(includeArchived: includeArchived);

  Stream<List<Account>> watch({bool includeArchived = false}) =>
      _repository.watchAll(includeArchived: includeArchived);
}
