enum BillDocumentType {
  boleto,
  pix,
  other;

  String get label => switch (this) {
        BillDocumentType.boleto => 'Boleto',
        BillDocumentType.pix => 'PIX',
        BillDocumentType.other => 'Outro',
      };

  static BillDocumentType fromString(String value) => switch (value) {
        'boleto' => BillDocumentType.boleto,
        'pix' => BillDocumentType.pix,
        'other' => BillDocumentType.other,
        _ => throw ArgumentError('BillDocumentType inválido: $value'),
      };
}
