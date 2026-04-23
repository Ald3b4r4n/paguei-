import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/transactions/create_transaction_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

// Fake repository shared across test files in this group.
class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];
  final Map<String, int> accountBalances = {};

  @override
  Future<Transaction> create({
    required String id,
    required String accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required DateTime date,
    String? categoryId,
    String? billId,
    bool isRecurring = false,
    String? recurrenceGroupId,
    String? notes,
  }) async {
    final txn = Transaction.create(
      id: id,
      accountId: accountId,
      type: type,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      billId: billId,
      isRecurring: isRecurring,
      notes: notes,
    );
    _transactions.add(txn);
    _applyEffect(accountId, txn.balanceEffect);
    return txn;
  }

  @override
  Future<Transaction> createTransfer({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required String description,
    required DateTime date,
    String? notes,
  }) async {
    final txn = Transaction.create(
      id: id,
      accountId: fromAccountId,
      type: TransactionType.transfer,
      amount: amount,
      description: description,
      date: date,
      notes: notes,
    );
    _transactions.add(txn);
    _applyEffect(fromAccountId, -amount);
    _applyEffect(toAccountId, amount);
    return txn;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    if (idx == -1) throw NotFoundException(message: 'Not found');
    final old = _transactions[idx];
    _applyEffect(old.accountId, -old.balanceEffect);
    _applyEffect(transaction.accountId, transaction.balanceEffect);
    _transactions[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    final txn = _transactions.firstWhere((t) => t.id == id);
    _applyEffect(txn.accountId, -txn.balanceEffect);
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Transaction>> getByMonth(
      {required int year, required int month}) async {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  @override
  Future<List<Transaction>> getByAccount(String accountId) async =>
      _transactions.where((t) => t.accountId == accountId).toList();

  @override
  Future<List<Transaction>> getByCategory(String categoryId) async =>
      _transactions.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<List<Transaction>> getByDateRange(
          {required DateTime start, required DateTime end}) async =>
      _transactions
          .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
          .toList();

  @override
  Future<Transaction?> getById(String id) async =>
      _transactions.where((t) => t.id == id).firstOrNull;

  @override
  Stream<List<Transaction>> watchByMonth(
          {required int year, required int month}) =>
      Stream.value(_transactions
          .where((t) => t.date.year == year && t.date.month == month)
          .toList());

  @override
  Future<Money> getMonthlySummary({
    required int year,
    required int month,
    TransactionType? type,
    String? accountId,
  }) async {
    final txns = _transactions.where((t) =>
        t.date.year == year &&
        t.date.month == month &&
        (accountId == null || t.accountId == accountId) &&
        (type == null || t.type == type));

    if (type == null) {
      return txns.fold<Money>(Money.zero, (sum, t) => sum + t.balanceEffect);
    }
    return txns.fold<Money>(Money.zero, (sum, t) => sum + t.amount);
  }

  void _applyEffect(String accountId, Money delta) {
    accountBalances[accountId] =
        (accountBalances[accountId] ?? 0) + delta.cents;
  }

  Money balanceFor(String accountId) => Money(accountBalances[accountId] ?? 0);
}

// ---------------------------------------------------------------------------

void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository();
    repository.accountBalances['acc-1'] = 100000; // R$ 1.000,00
  });

  group('CreateTransactionUseCase behavior', () {
    test('income increases account balance', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(50000), // R$ 500,00
        description: 'Salário',
        date: DateTime.utc(2026, 4, 1),
      );

      expect(
          repository.balanceFor('acc-1'), equals(Money(150000))); // R$ 1.500,00
    });

    test('expense decreases account balance', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(30000), // R$ 300,00
        description: 'Aluguel',
        date: DateTime.utc(2026, 4, 5),
      );

      expect(repository.balanceFor('acc-1'), equals(Money(70000))); // R$ 700,00
    });

    test('ValidationException propaga para amount zero', () {
      expect(
        () => repository.create(
          id: 'txn-1',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money.zero,
          description: 'Teste',
          date: DateTime.utc(2026, 4, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ValidationException para accountId vazio', () {
      final useCase = CreateTransactionUseCase(repository);

      expect(
        useCase.execute(
          id: 'txn-1',
          accountId: '   ',
          type: TransactionType.income,
          amount: Money(10000),
          description: 'Salário',
          date: DateTime.utc(2026, 4, 1),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Escolha um local do dinheiro',
          ),
        ),
      );
    });

    test('transação criada é persistida no repositório', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(5000),
        description: 'Café',
        date: DateTime.utc(2026, 4, 19),
      );

      final txns = await repository.getByMonth(year: 2026, month: 4);
      expect(txns.length, equals(1));
      expect(txns.first.id, equals('txn-1'));
    });

    test('múltiplas transações acumulam corretamente no saldo', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(200000),
        description: 'Freelance',
        date: DateTime.utc(2026, 4, 10),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(50000),
        description: 'Mercado',
        date: DateTime.utc(2026, 4, 11),
      );

      // 100000 + 200000 - 50000 = 250000
      expect(repository.balanceFor('acc-1'), equals(Money(250000)));
    });
  });
}
