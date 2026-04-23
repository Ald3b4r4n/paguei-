enum BillStatus {
  pending,
  paid,
  overdue,
  cancelled;

  String get label => switch (this) {
        BillStatus.pending => 'Pendente',
        BillStatus.paid => 'Pago',
        BillStatus.overdue => 'Vencido',
        BillStatus.cancelled => 'Cancelado',
      };

  static BillStatus fromString(String value) => switch (value) {
        'pending' => BillStatus.pending,
        'paid' => BillStatus.paid,
        'overdue' => BillStatus.overdue,
        'cancelled' => BillStatus.cancelled,
        _ => throw ArgumentError('BillStatus inválido: $value'),
      };
}
