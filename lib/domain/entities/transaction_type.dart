enum TransactionType {
  income,
  expense,
  transfer;

  String get label => switch (this) {
        TransactionType.income => 'Receita',
        TransactionType.expense => 'Despesa',
        TransactionType.transfer => 'Transferência',
      };
}
