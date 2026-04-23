enum CategoryType {
  income,
  expense,
  both;

  String get label => switch (this) {
        CategoryType.income => 'Receita',
        CategoryType.expense => 'Despesa',
        CategoryType.both => 'Ambos',
      };
}
