enum FundType {
  emergency,
  goal,
  savings;

  String get label => switch (this) {
        FundType.emergency => 'Reserva de Emergência',
        FundType.goal => 'Meta',
        FundType.savings => 'Poupança',
      };

  static FundType fromString(String value) => switch (value) {
        'emergency' => FundType.emergency,
        'goal' => FundType.goal,
        'savings' => FundType.savings,
        _ => throw ArgumentError('FundType inválido: $value'),
      };
}
