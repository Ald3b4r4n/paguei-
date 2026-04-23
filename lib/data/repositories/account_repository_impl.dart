import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/daos/accounts_dao.dart';
import 'package:paguei/data/models/account_model.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dao);

  final AccountsDao _dao;

  @override
  Future<List<Account>> getAll({bool includeArchived = false}) async {
    final rows = await _dao.getAll(includeArchived: includeArchived);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Account?> getById(String id) async {
    final row = await _dao.getById(id);
    return row?.toDomain();
  }

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    return _dao
        .watchAll(includeArchived: includeArchived)
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<Account> create({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance = Money.zero,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) async {
    // Domain validation happens inside Account.create().
    final account = Account.create(
      id: id,
      name: name,
      type: type,
      currentBalance: initialBalance,
      currency: currency,
      color: color,
      icon: icon,
    );

    await _dao.insertAccount(account.toCompanion());
    return account;
  }

  @override
  Future<Account> update(Account account) async {
    final exists = await _dao.getById(account.id);
    if (exists == null) {
      throw NotFoundException(
        message: 'Local do dinheiro não encontrado: ${account.id}',
      );
    }
    await _dao.updateAccount(account.toCompanion());
    return account;
  }

  @override
  Future<void> archive(String id) async {
    final exists = await _dao.getById(id);
    if (exists == null) {
      throw NotFoundException(message: 'Local do dinheiro não encontrado: $id');
    }
    await _dao.archiveAccount(id);
  }

  @override
  Future<void> unarchive(String id) async {
    final exists = await _dao.getById(id);
    if (exists == null) {
      throw NotFoundException(message: 'Local do dinheiro não encontrado: $id');
    }
    await _dao.unarchiveAccount(id);
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteAccount(id);
  }
}
