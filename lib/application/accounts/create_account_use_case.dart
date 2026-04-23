import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class CreateAccountUseCase {
  const CreateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Account> execute({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance = Money.zero,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) {
    // Validation is delegated to Account.create() — throws ValidationException on violation.
    return _repository.create(
      id: id,
      name: name,
      type: type,
      initialBalance: initialBalance,
      currency: currency,
      color: color,
      icon: icon,
    );
  }
}
