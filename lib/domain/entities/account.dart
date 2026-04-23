import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currentBalance,
    required this.currency,
    required this.isArchived,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.create({
    required String id,
    required String name,
    required AccountType type,
    Money? currentBalance,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) {
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
    if (!_validCurrencies.contains(currency)) {
      throw ValidationException(message: 'Moeda inválida: $currency');
    }

    final now = DateTime.now().toUtc();
    return Account(
      id: id,
      name: name,
      type: type,
      currentBalance: currentBalance ?? Money.zero,
      currency: currency,
      isArchived: false,
      color: color,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
  }

  static const _validCurrencies = {'BRL', 'USD', 'EUR', 'GBP'};

  final String id;
  final String name;
  final AccountType type;
  final Money currentBalance;
  final String currency;
  final bool isArchived;
  final int color;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account archive() =>
      copyWith(isArchived: true, updatedAt: DateTime.now().toUtc());

  Account unarchive() =>
      copyWith(isArchived: false, updatedAt: DateTime.now().toUtc());

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    Money? currentBalance,
    String? currency,
    bool? isArchived,
    int? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      isArchived: isArchived ?? this.isArchived,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Account && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Account(id: $id, name: $name, type: $type)';
}
