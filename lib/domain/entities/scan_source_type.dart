enum ScanSourceType {
  camera,
  qrCode,
  image,
  pdf,
  txt,
  manual;

  String get label => switch (this) {
        ScanSourceType.camera => 'Câmera',
        ScanSourceType.qrCode => 'QR Code',
        ScanSourceType.image => 'Imagem',
        ScanSourceType.pdf => 'PDF',
        ScanSourceType.txt => 'Arquivo TXT',
        ScanSourceType.manual => 'Manual',
      };
}
