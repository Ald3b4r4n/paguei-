import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class FakeAccountRepository implements AccountRepository {
  final _store = <String, Account>{};

  @override
  Future<Account> create({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance = Money.zero,
    // Extra param for tests — not in interface
    Money? currentBalance,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) async {
    final now = DateTime.now().toUtc();
    final account = Account(
      id: id,
      name: name,
      type: type,
      currentBalance: currentBalance ?? initialBalance,
      currency: currency,
      isArchived: false,
      color: color,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    _store[id] = account;
    return account;
  }

  @override
  Future<List<Account>> getAll({bool includeArchived = false}) async {
    return _store.values
        .where((a) => includeArchived || !a.isArchived)
        .toList();
  }

  @override
  Future<Account?> getById(String id) async => _store[id];

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) =>
      Stream.value(
        _store.values.where((a) => includeArchived || !a.isArchived).toList(),
      );

  @override
  Future<Account> update(Account account) async {
    _store[account.id] = account;
    return account;
  }

  @override
  Future<void> archive(String id) async {
    final a = _store[id];
    if (a != null) {
      _store[id] = Account(
        id: a.id,
        name: a.name,
        type: a.type,
        currentBalance: a.currentBalance,
        currency: a.currency,
        isArchived: true,
        color: a.color,
        icon: a.icon,
        createdAt: a.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<void> unarchive(String id) async {
    final a = _store[id];
    if (a != null) {
      _store[id] = Account(
        id: a.id,
        name: a.name,
        type: a.type,
        currentBalance: a.currentBalance,
        currency: a.currency,
        isArchived: false,
        color: a.color,
        icon: a.icon,
        createdAt: a.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);
}
