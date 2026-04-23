enum DebtStatus {
  active,
  paid,
  renegotiated;

  String get label => switch (this) {
        DebtStatus.active => 'Ativa',
        DebtStatus.paid => 'Quitada',
        DebtStatus.renegotiated => 'Renegociada',
      };

  static DebtStatus fromString(String value) => switch (value) {
        'active' => DebtStatus.active,
        'paid' => DebtStatus.paid,
        'renegotiated' => DebtStatus.renegotiated,
        _ => throw ArgumentError('DebtStatus inválido: $value'),
      };
}
