import 'package:mobile_scanner/mobile_scanner.dart';

/// Raw scan event emitted by the hardware scanner.
final class ScanEvent {
  const ScanEvent({required this.rawValue, required this.format});

  final String rawValue;
  final BarcodeFormat format;

  bool get isQrCode => format == BarcodeFormat.qrCode;
  bool get is1D =>
      format == BarcodeFormat.itf14 ||
      format == BarcodeFormat.code128 ||
      format == BarcodeFormat.code39 ||
      format == BarcodeFormat.codabar;
}

/// Callback invoked on each successful barcode detection.
typedef OnScanDetected = void Function(ScanEvent event);

/// Abstract datasource so the scanner widget can be swapped for tests.
abstract interface class BarcodeScannerDatasource {
  void setDetectionCallback(OnScanDetected callback);
  Future<void> start();
  Future<void> stop();
  Future<void> toggleTorch();
  Future<void> switchCamera();
  void dispose();
}

/// Production implementation using [MobileScannerController].
final class MobileBarcodeScannerDatasource implements BarcodeScannerDatasource {
  MobileBarcodeScannerDatasource()
      : controller = MobileScannerController(
          formats: const [
            BarcodeFormat.itf14,
            BarcodeFormat.code128,
            BarcodeFormat.qrCode,
            BarcodeFormat.codabar,
          ],
          detectionSpeed: DetectionSpeed.normal,
          returnImage: false,
        );

  final MobileScannerController controller;
  OnScanDetected? _callback;

  void handleCapture(BarcodeCapture capture) {
    final callback = _callback;
    if (callback == null) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        callback(ScanEvent(rawValue: raw, format: barcode.format));
        break;
      }
    }
  }

  @override
  void setDetectionCallback(OnScanDetected callback) {
    _callback = callback;
  }

  @override
  Future<void> start() => controller.start();

  @override
  Future<void> stop() => controller.stop();

  @override
  Future<void> toggleTorch() => controller.toggleTorch();

  @override
  Future<void> switchCamera() => controller.switchCamera();

  @override
  void dispose() => controller.dispose();
}
