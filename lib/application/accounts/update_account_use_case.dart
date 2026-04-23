import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class UpdateAccountUseCase {
  const UpdateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Account> execute({
    required String id,
    String? name,
    AccountType? type,
    Money? currentBalance,
    int? color,
    String? icon,
  }) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw NotFoundException(message: 'Local do dinheiro não encontrado: $id');
    }

    // Validate the new name before applying.
    if (name != null) {
      if (name.trim().isEmpty) {
        throw const ValidationException(
          message: 'Nome do local do dinheiro não pode ser vazio.',
        );
      }
      if (name.length > 100) {
        throw const ValidationException(
          message:
              'Nome do local do dinheiro não pode ter mais de 100 caracteres.',
        );
      }
    }

    final updated = existing.copyWith(
      name: name,
      type: type,
      currentBalance: currentBalance,
      color: color,
      icon: icon,
      updatedAt: DateTime.now().toUtc(),
    );

    return _repository.update(updated);
  }
}
