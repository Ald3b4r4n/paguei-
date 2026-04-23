enum AccountType {
  checking,
  savings,
  wallet,
  investment;

  String get label => switch (this) {
        AccountType.checking => 'Banco',
        AccountType.savings => 'Poupança',
        AccountType.wallet => 'Carteira',
        AccountType.investment => 'Investimentos',
      };
}
