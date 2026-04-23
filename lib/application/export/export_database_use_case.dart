import 'package:paguei/application/export/restore_service.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/repositories/category_repository.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';

/// Reads every entity from the local database and returns a serialisable map
/// suitable for passing to [BackupService.writeBackup].
///
/// The returned map has the following shape:
/// ```json
/// {
///   "accounts": [ {...}, ... ],
///   "categories": [ {...}, ... ],
///   "transactions": [ {...}, ... ],
///   "bills": [ {...}, ... ],
///   "funds": [ {...}, ... ],
///   "debts": [ {...}, ... ]
/// }
/// ```
///
/// Serialisation format for each entity type is defined by [EntitySerializers].
final class ExportDatabaseUseCase {
  const ExportDatabaseUseCase({
    required AccountRepository accounts,
    required TransactionRepository transactions,
    required BillRepository bills,
    required FundRepository funds,
    required DebtRepository debts,
    required CategoryRepository categories,
  })  : _accounts = accounts,
        _transactions = transactions,
        _bills = bills,
        _funds = funds,
        _debts = debts,
        _categories = categories;

  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final BillRepository _bills;
  final FundRepository _funds;
  final DebtRepository _debts;
  final CategoryRepository _categories;

  /// Exports all data to a JSON-compatible map.
  ///
  /// Run in an isolate for large datasets (> [AppConstants.csvExportIsolateThreshold]).
  Future<Map<String, dynamic>> execute() async {
    // Fetch concurrently where possible.
    final results = await Future.wait([
      _accounts.getAll(includeArchived: true),
      _categories.getAll(),
      _bills.getAll(),
      _funds.getAll(),
      _debts.getAll(),
    ]);

    final accounts = results[0] as List<Account>;
    final categories = results[1] as List<Category>;
    final bills = results[2] as List<Bill>;
    final funds = results[3] as List<Fund>;
    final debts = results[4] as List<Debt>;

    // Transactions require a date-range query since there is no getAll().
    // Use a sufficiently wide range to capture everything.
    final transactions = await _transactions.getByDateRange(
      start: DateTime.utc(2000),
      end: DateTime.utc(2100),
    );

    return {
      'accounts': accounts
          .map<Map<String, dynamic>>(EntitySerializers.accountToJson)
          .toList(),
      'categories': categories
          .map<Map<String, dynamic>>(EntitySerializers.categoryToJson)
          .toList(),
      'transactions': transactions
          .map<Map<String, dynamic>>(EntitySerializers.transactionToJson)
          .toList(),
      'bills': bills
          .map<Map<String, dynamic>>(EntitySerializers.billToJson)
          .toList(),
      'funds': funds
          .map<Map<String, dynamic>>(EntitySerializers.fundToJson)
          .toList(),
      'debts': debts
          .map<Map<String, dynamic>>(EntitySerializers.debtToJson)
          .toList(),
    };
  }
}
