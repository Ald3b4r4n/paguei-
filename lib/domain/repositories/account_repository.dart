import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

abstract interface class AccountRepository {
  Future<List<Account>> getAll({bool includeArchived = false});

  Future<Account?> getById(String id);

  Stream<List<Account>> watchAll({bool includeArchived = false});

  Future<Account> create({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance,
    String currency,
    int color,
    String icon,
  });

  Future<Account> update(Account account);

  Future<void> archive(String id);

  Future<void> unarchive(String id);

  Future<void> delete(String id);
}
