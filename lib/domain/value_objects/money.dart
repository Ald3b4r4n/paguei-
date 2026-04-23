import 'package:intl/intl.dart';

final class Money implements Comparable<Money> {
  const Money(this._cents);

  factory Money.fromDouble(double value) {
    final scaled = value * 100;
    final adjusted = scaled >= 0 ? scaled + 1e-7 : scaled - 1e-7;
    return Money(adjusted.round());
  }

  static const Money zero = Money(0);

  final int _cents;

  int get cents => _cents;

  double get amount => _cents / 100.0;

  bool get isZero => _cents == 0;
  bool get isPositive => _cents > 0;
  bool get isNegative => _cents < 0;

  Money operator +(Money other) => Money(_cents + other._cents);
  Money operator -(Money other) => Money(_cents - other._cents);
  Money operator *(num factor) => Money((_cents * factor).round());
  Money operator -() => Money(-_cents);

  Money abs() => Money(_cents.abs());

  bool operator <(Money other) => _cents < other._cents;
  bool operator <=(Money other) => _cents <= other._cents;
  bool operator >(Money other) => _cents > other._cents;
  bool operator >=(Money other) => _cents >= other._cents;

  @override
  int compareTo(Money other) => _cents.compareTo(other._cents);

  String formatted() {
    final format = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  @override
  String toString() => formatted();

  @override
  bool operator ==(Object other) => other is Money && other._cents == _cents;

  @override
  int get hashCode => _cents.hashCode;
}
