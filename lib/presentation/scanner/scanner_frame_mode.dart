import 'dart:ui';

import 'package:mobile_scanner/mobile_scanner.dart';

enum ScannerFrameMode {
  auto,
  qr,
  barcode;

  String get label => switch (this) {
        ScannerFrameMode.auto => '[ QRCode PIX ou boleto ]',
        ScannerFrameMode.qr => '[ QRCode PIX ]',
        ScannerFrameMode.barcode => '[ Código de barras ]',
      };
}

const acceptedScanFormats = <BarcodeFormat>[
  BarcodeFormat.qrCode,
  BarcodeFormat.code128,
  BarcodeFormat.itf14,
  BarcodeFormat.itf2of5,
  BarcodeFormat.itf2of5WithChecksum,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.pdf417,
];

const qrScanFormats = <BarcodeFormat>[
  BarcodeFormat.qrCode,
];

const barcodeScanFormats = <BarcodeFormat>[
  BarcodeFormat.code128,
  BarcodeFormat.itf14,
  BarcodeFormat.itf2of5,
  BarcodeFormat.itf2of5WithChecksum,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.pdf417,
];

final _pixPayloadWithCrc = RegExp('000201[\\s\\S]*?6304[0-9A-Fa-f]{4}');

bool isQrFormat(BarcodeFormat format) => format == BarcodeFormat.qrCode;

bool isLinearBarcodeFormat(BarcodeFormat format) =>
    barcodeScanFormats.contains(format);

bool containsPixPayload(String raw) {
  final trimmed = raw.trim();
  return trimmed.startsWith('000201') || _pixPayloadWithCrc.hasMatch(trimmed);
}

bool shouldTreatAsQrPayment(Barcode barcode) =>
    isQrFormat(barcode.format) || containsPixPayload(barcode.rawValue ?? '');

bool captureContainsPixPayload(Iterable<Barcode> barcodes) =>
    barcodes.any((barcode) => containsPixPayload(barcode.rawValue ?? ''));

ScannerFrameMode inferScannerFrameMode(Iterable<Barcode> barcodes) {
  var qrScore = 0;
  var barcodeScore = 0;
  var hasPixPayload = false;

  for (final barcode in barcodes) {
    final raw = barcode.rawValue?.trim() ?? '';
    final size = barcode.size;
    final hasSize = size.width > 0 && size.height > 0;
    final aspectRatio = hasSize ? size.width / size.height : 1.0;

    if (isQrFormat(barcode.format)) qrScore += 4;
    if (containsPixPayload(raw)) {
      qrScore += 6;
      hasPixPayload = true;
    }
    if (hasSize && aspectRatio >= 0.72 && aspectRatio <= 1.28) qrScore += 2;

    if (isLinearBarcodeFormat(barcode.format)) barcodeScore += 4;
    if (_looksLikeBoletoDigits(raw)) barcodeScore += 3;
    if (hasSize && aspectRatio >= 1.65) barcodeScore += 2;
  }

  if (hasPixPayload) return ScannerFrameMode.qr;
  if (qrScore == 0 && barcodeScore == 0) return ScannerFrameMode.auto;
  if (qrScore > barcodeScore) return ScannerFrameMode.qr;
  if (barcodeScore > qrScore) return ScannerFrameMode.barcode;
  return ScannerFrameMode.auto;
}

List<Barcode> prioritizeBarcodesForMode(
  Iterable<Barcode> barcodes,
  ScannerFrameMode mode,
) {
  return List<Barcode>.of(barcodes)
    ..sort((a, b) => _scanPriority(b, mode).compareTo(_scanPriority(a, mode)));
}

Rect scannerFrameFor(Size size, ScannerFrameMode mode) {
  final width = size.width;
  final height = size.height;
  final center = Offset(width / 2, height * 0.42);

  if (mode == ScannerFrameMode.qr) {
    final side = (width * 0.82).clamp(260.0, 430.0);
    return Rect.fromCenter(center: center, width: side, height: side);
  }

  final cutWidth = width * 0.88;
  final cutHeight = (cutWidth * 0.34).clamp(110.0, 172.0);
  return Rect.fromCenter(center: center, width: cutWidth, height: cutHeight);
}

Rect? scanWindowForMode(Size size, ScannerFrameMode mode) {
  if (mode == ScannerFrameMode.auto) return null;

  var padding = mode == ScannerFrameMode.qr ? 42.0 : 24.0;
  final frame = scannerFrameFor(size, mode);
  if (mode == ScannerFrameMode.qr) {
    final maxSquarePadding = <double>[
      frame.left,
      size.width - frame.right,
      frame.top,
      size.height - frame.bottom,
    ].reduce((a, b) => a < b ? a : b);
    padding = padding.clamp(0.0, maxSquarePadding);
  }
  final full = Offset.zero & size;
  return frame.inflate(padding).intersect(full);
}

bool _looksLikeBoletoDigits(String raw) {
  final digits = raw.replaceAll(RegExp(r'[\s.\-]'), '');
  return RegExp(r'^\d{44}$|^\d{47}$').hasMatch(digits);
}

int _scanPriority(Barcode barcode, ScannerFrameMode mode) {
  final raw = barcode.rawValue?.trim() ?? '';
  var priority = 0;

  if (isQrFormat(barcode.format)) priority += 40;
  if (containsPixPayload(raw)) priority += 70;
  if (isLinearBarcodeFormat(barcode.format)) priority += 30;
  if (_looksLikeBoletoDigits(raw)) priority += 35;

  if (mode == ScannerFrameMode.qr && isQrFormat(barcode.format)) priority += 20;
  if (mode == ScannerFrameMode.barcode &&
      isLinearBarcodeFormat(barcode.format)) {
    priority += 20;
  }

  return priority;
}
