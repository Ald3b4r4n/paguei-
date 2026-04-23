import 'package:drift/drift.dart' show Value;
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

/// Maps between the Drift [AccountsTableData] row and the domain [Account] entity.
extension AccountModelMapper on AccountsTableData {
  Account toDomain() {
    return Account(
      id: id,
      name: name,
      type: _accountTypeFromString(type),
      currentBalance: Money(currentBalanceCents),
      currency: currency,
      isArchived: isArchived,
      color: color,
      icon: icon,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension AccountToCompanion on Account {
  AccountsTableCompanion toCompanion() {
    return AccountsTableCompanion.insert(
      id: id,
      name: name,
      type: type.name,
      currentBalanceCents: Value(currentBalance.cents),
      currency: Value(currency),
      isArchived: Value(isArchived),
      color: Value(color),
      icon: Value(icon),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

AccountType _accountTypeFromString(String value) {
  return AccountType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AccountType.checking,
  );
}
