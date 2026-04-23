import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paguei/application/scanner/extract_bill_from_image_use_case.dart';
import 'package:paguei/application/scanner/extract_bill_from_pdf_use_case.dart';
import 'package:paguei/application/scanner/extract_bill_from_txt_use_case.dart';
import 'package:paguei/application/scanner/pix_dynamic_payload_resolver.dart';
import 'package:paguei/application/scanner/scan_barcode_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/datasources/permissions/camera_permission_datasource.dart';
import 'package:paguei/data/datasources/scanner/file_picker_datasource.dart';
import 'package:paguei/data/datasources/scanner/ocr_datasource.dart';
import 'package:paguei/data/datasources/scanner/pdf_extractor_datasource.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/scanner/widgets/camera_permission_explainer.dart';
import 'package:paguei/presentation/scanner/scanner_frame_mode.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _cameraPermissionProvider = Provider<CameraPermissionDatasource>(
    (_) => const CameraPermissionDatasourceImpl());

final _scanBarcodeUseCaseProvider =
    Provider<ScanBarcodeUseCase>((_) => const ScanBarcodeUseCase());

final _pixDynamicPayloadResolverProvider =
    Provider<PixDynamicPayloadResolver>((_) => PixDynamicPayloadResolver());

final _filePickerProvider =
    Provider<FilePickerDatasource>((_) => const FlutterFilePickerDatasource());

enum BillScanInitialAction {
  scan,
  importPdf,
  importImage,
  importAny,
}

// ---------------------------------------------------------------------------
// Screen sealed state
// ---------------------------------------------------------------------------

sealed class ScanScreenState {
  const ScanScreenState();
}

class ScanIdle extends ScanScreenState {
  const ScanIdle();
}

class ScanCheckingPermission extends ScanScreenState {
  const ScanCheckingPermission();
}

class ScanPermissionDenied extends ScanScreenState {
  const ScanPermissionDenied({this.isPermanent = false});
  final bool isPermanent;
}

class ScanScanning extends ScanScreenState {
  const ScanScanning();
}

class ScanImporting extends ScanScreenState {
  const ScanImporting();
}

class ScanSuccess extends ScanScreenState {
  const ScanSuccess(this.data);
  final ParsedBillData data;
}

class ScanError extends ScanScreenState {
  const ScanError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BillScanScreen extends ConsumerStatefulWidget {
  const BillScanScreen({
    super.key,
    this.initialAction = BillScanInitialAction.scan,
  });

  final BillScanInitialAction initialAction;

  @override
  ConsumerState<BillScanScreen> createState() => _BillScanScreenState();
}

class _BillScanScreenState extends ConsumerState<BillScanScreen> {
  ScanScreenState _state = const ScanIdle();
  MobileScannerController? _controller;
  ScannerFrameMode _frameMode = ScannerFrameMode.auto;
  bool _torchOn = false;
  bool _processed = false;
  bool _isHandlingCapture = false;

  @override
  void initState() {
    super.initState();
    switch (widget.initialAction) {
      case BillScanInitialAction.scan:
        _checkPermissionAndStart();
      case BillScanInitialAction.importPdf:
      case BillScanInitialAction.importImage:
      case BillScanInitialAction.importAny:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _importDocument(widget.initialAction);
        });
    }
  }

  Future<void> _checkPermissionAndStart() async {
    setState(() => _state = const ScanCheckingPermission());

    final permission = ref.read(_cameraPermissionProvider);
    var status = await permission.getStatus();

    if (status == CameraPermissionStatus.denied) {
      status = await permission.request();
    }

    switch (status) {
      case CameraPermissionStatus.granted:
        _startScanner();
      case CameraPermissionStatus.permanentlyDenied:
        setState(() => _state = const ScanPermissionDenied(isPermanent: true));
      case CameraPermissionStatus.restricted:
      case CameraPermissionStatus.denied:
        setState(() => _state = const ScanPermissionDenied());
    }
  }

  void _startScanner() {
    _frameMode = ScannerFrameMode.auto;
    _controller = MobileScannerController(
      formats: acceptedScanFormats,
      cameraResolution: const Size(1920, 1080),
      detectionSpeed: DetectionSpeed.unrestricted,
      detectionTimeoutMs: 40,
      autoZoom: true,
      initialZoom: 0.0,
      returnImage: false,
    );
    _startFramePulse();
    setState(() => _state = const ScanScanning());
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    unawaited(_handleBarcodeDetected(capture));
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_processed || _isHandlingCapture) return;
    _isHandlingCapture = true;

    final detectedMode = inferScannerFrameMode(capture.barcodes);
    final shouldLockDetectedMode = detectedMode == ScannerFrameMode.barcode ||
        (detectedMode == ScannerFrameMode.qr &&
            captureContainsPixPayload(capture.barcodes));
    if (shouldLockDetectedMode &&
        detectedMode != ScannerFrameMode.auto &&
        detectedMode != _frameMode &&
        mounted) {
      setState(() => _frameMode = detectedMode);
    }

    try {
      final result = await _parseBarcodeCapture(
        capture,
        fallbackSource: ScanSourceType.camera,
        updateFrameMode: true,
      );
      if (result == null) {
        _logScannerFailure('capture_sem_codigo_valido', detectedMode);
        return;
      }

      _processed = true;
      _stopFramePulse();
      HapticFeedback.mediumImpact();
      await _controller?.stop();
      if (mounted) setState(() => _state = ScanSuccess(result));
    } finally {
      if (!_processed) _isHandlingCapture = false;
    }
  }

  Future<ParsedBillData?> _parseBarcodeCapture(
    BarcodeCapture capture, {
    required ScanSourceType fallbackSource,
    required bool updateFrameMode,
  }) async {
    final detectedMode = inferScannerFrameMode(capture.barcodes);
    final prioritized = prioritizeBarcodesForMode(
      capture.barcodes,
      detectedMode == ScannerFrameMode.auto ? _frameMode : detectedMode,
    );

    for (final barcode in prioritized) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) {
        _logScannerFailure('codigo_sem_raw_value', detectedMode);
        continue;
      }

      try {
        final isQrPayment = shouldTreatAsQrPayment(barcode);
        final source = isQrPayment ? ScanSourceType.qrCode : fallbackSource;
        final nextMode =
            isQrPayment ? ScannerFrameMode.qr : ScannerFrameMode.barcode;
        final result = ref
            .read(_scanBarcodeUseCaseProvider)
            .execute(raw: raw, source: source);
        final enriched = await _enrichIfPix(result);
        if (updateFrameMode && _frameMode != nextMode && mounted) {
          setState(() => _frameMode = nextMode);
        }
        return enriched;
      } on ValidationException catch (error, stackTrace) {
        _logScannerFailure(
          isQrFormat(barcode.format)
              ? 'falha_parse_qr_pix'
              : 'falha_parse_barcode',
          detectedMode,
          error,
          stackTrace,
        );
        continue;
      }
    }

    return null;
  }

  Future<ParsedBillData> _enrichIfPix(ParsedBillData data) async {
    if (!data.hasPixCode) return data;

    final enriched =
        await ref.read(_pixDynamicPayloadResolverProvider).enrich(data);
    if (!enriched.hasAmount || enriched.beneficiary == null) {
      developer.log(
        'Payload PIX incompleto apos parse/enriquecimento: '
        'amount=${enriched.hasAmount}, beneficiary=${enriched.beneficiary != null}, '
        'key=${enriched.pixKey != null}, location=${enriched.pixLocationUrl != null}, '
        'txid=${enriched.pixTxId != null}',
        name: 'paguei.scanner.pix',
      );
    }
    return enriched;
  }

  void _logScannerFailure(
    String event,
    ScannerFrameMode mode, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      'Scanner $event mode=${mode.name}',
      name: 'paguei.scanner',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _navigateToReview(ParsedBillData data) {
    context.push('/boletos/review', extra: data);
  }

  Future<void> _importDocument([
    BillScanInitialAction action = BillScanInitialAction.importAny,
  ]) async {
    _stopFramePulse();
    setState(() => _state = const ScanImporting());

    try {
      final picker = ref.read(_filePickerProvider);
      final picked = switch (action) {
        BillScanInitialAction.importPdf => await picker.pickPdf(),
        BillScanInitialAction.importImage => await picker.pickImage(),
        BillScanInitialAction.scan ||
        BillScanInitialAction.importAny =>
          await picker.pickAny(),
      };
      if (picked == null) {
        if (_controller != null) {
          _startFramePulse();
          setState(() => _state = const ScanScanning());
        } else {
          setState(
              () => _state = const ScanError('Nenhum arquivo selecionado.'));
        }
        return;
      }

      final extension = picked.name.split('.').last.toLowerCase();
      final data = switch (extension) {
        'pdf' => await const ExtractBillFromPdfUseCase(
            SyncfusionPdfExtractorDatasource(),
          ).execute(picked.file),
        'txt' => await const ExtractBillFromTxtUseCase().execute(picked.file),
        _ => await _extractImage(picked.file),
      };

      if (!data.hasBarcode &&
          !data.hasPixCode &&
          !data.hasAmount &&
          !data.hasDueDate &&
          data.beneficiary == null) {
        setState(() => _state = const ScanError(
              'Não encontramos dados de boleto ou PIX nesse arquivo.',
            ));
        return;
      }

      if (mounted) {
        _navigateToReview(data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = ScanError('Erro ao importar arquivo: $e'));
      }
    }
  }

  Future<ParsedBillData> _extractImage(File imageFile) async {
    final scanResult = await _extractCodeFromImage(imageFile);
    if (scanResult != null) return scanResult;

    final ocr = MlKitOcrDatasource();
    try {
      return await ExtractBillFromImageUseCase(ocr).execute(imageFile);
    } finally {
      await ocr.close();
    }
  }

  Future<ParsedBillData?> _extractCodeFromImage(File imageFile) async {
    final qrCapture = await _analyzeImageWithFormats(imageFile, qrScanFormats);
    if (qrCapture != null) {
      final qrResult = await _parseBarcodeCapture(
        qrCapture,
        fallbackSource: ScanSourceType.image,
        updateFrameMode: false,
      );
      if (qrResult != null) return qrResult;
    }

    final barcodeCapture =
        await _analyzeImageWithFormats(imageFile, barcodeScanFormats);
    if (barcodeCapture != null) {
      return _parseBarcodeCapture(
        barcodeCapture,
        fallbackSource: ScanSourceType.image,
        updateFrameMode: false,
      );
    }

    return null;
  }

  Future<BarcodeCapture?> _analyzeImageWithFormats(
    File imageFile,
    List<BarcodeFormat> formats,
  ) async {
    final scanner = MobileScannerController(
      autoStart: false,
      formats: formats,
    );
    try {
      return await scanner.analyzeImage(
        imageFile.path,
        formats: formats,
      );
    } finally {
      await scanner.dispose();
    }
  }

  @override
  void dispose() {
    _stopFramePulse();
    _controller?.dispose();
    super.dispose();
  }

  void _startFramePulse() {
    _frameMode = ScannerFrameMode.auto;
  }

  void _stopFramePulse() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Escanear pagamento'),
        actions: [
          if (_state is ScanScanning)
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                await _controller?.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
        ],
      ),
      body: switch (_state) {
        ScanIdle() ||
        ScanCheckingPermission() ||
        ScanImporting() =>
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ScanPermissionDenied(isPermanent: final perm) =>
          CameraPermissionExplainer(
            isPermanentlyDenied: perm,
            onAllowPressed: _checkPermissionAndStart,
            onDenyPressed: _importDocument,
            onOpenSettingsPressed: () =>
                ref.read(_cameraPermissionProvider).openSettings(),
          ),
        ScanScanning() => _LiveScannerOverlay(
            controller: _controller!,
            frameMode: _frameMode,
            onDetect: _onBarcodeDetected,
            onImport: _importDocument,
            onManualEntry: () => context.push(AppRoutes.billNew),
          ),
        ScanSuccess(data: final data) => _ScanSuccessOverlay(
            data: data,
            onContinue: () => _navigateToReview(data),
            onRescan: () {
              _processed = false;
              _controller?.start();
              _frameMode = ScannerFrameMode.auto;
              _startFramePulse();
              setState(() => _state = const ScanScanning());
            },
          ),
        ScanError(message: final msg) => _ScanErrorOverlay(
            message: msg,
            onRetry: () {
              _processed = false;
              if (widget.initialAction == BillScanInitialAction.scan &&
                  _controller != null) {
                _frameMode = ScannerFrameMode.auto;
                _startFramePulse();
                setState(() => _state = const ScanScanning());
              } else {
                _importDocument(widget.initialAction);
              }
            },
          ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Live scanner overlay
// ---------------------------------------------------------------------------

class _LiveScannerOverlay extends StatelessWidget {
  const _LiveScannerOverlay({
    required this.controller,
    required this.frameMode,
    required this.onDetect,
    required this.onImport,
    required this.onManualEntry,
  });

  final MobileScannerController controller;
  final ScannerFrameMode frameMode;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onImport;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanWindow = scanWindowForMode(constraints.biggest, frameMode);
        return Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: onDetect,
              tapToFocus: true,
              scanWindow: scanWindow,
              scanWindowUpdateThreshold: 16,
            ),
            _ScannerGuideOverlay(mode: frameMode),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Aponte para QRCode PIX ou código de barras.\nA câmera alterna automaticamente.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onImport,
                    icon: const Icon(Icons.image_search_outlined,
                        color: Colors.white),
                    label: const Text(
                      'Ler QR da imagem/PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onManualEntry,
                    icon:
                        const Icon(Icons.edit_outlined, color: Colors.white70),
                    label: const Text(
                      'Inserir manualmente',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Scanner guide overlay
// ---------------------------------------------------------------------------

class _ScannerGuideOverlay extends StatefulWidget {
  const _ScannerGuideOverlay({required this.mode});

  final ScannerFrameMode mode;

  @override
  State<_ScannerGuideOverlay> createState() => _ScannerGuideOverlayState();
}

class _ScannerGuideOverlayState extends State<_ScannerGuideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final rect = scannerFrameFor(size, widget.mode);
        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ViewfinderPainter(
                  mode: widget.mode,
                  progress: _controller.value,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: rect.left,
              top: rect.top - 46,
              width: rect.width,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      widget.mode.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({
    required this.mode,
    required this.progress,
  });

  final ScannerFrameMode mode;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = scannerFrameFor(size, mode);

    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, cutPath),
      overlay,
    );

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      border,
    );

    final corner = Paint()
      ..color = const Color(0xFF35D982)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final cornerSize = mode == ScannerFrameMode.qr ? 34.0 : 28.0;

    canvas.drawLine(rect.topLeft + Offset(0, cornerSize), rect.topLeft, corner);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerSize, 0), corner);
    canvas.drawLine(
      rect.topRight - Offset(cornerSize, 0),
      rect.topRight,
      corner,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerSize),
      corner,
    );
    canvas.drawLine(
      rect.bottomLeft - Offset(0, cornerSize),
      rect.bottomLeft,
      corner,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerSize, 0),
      corner,
    );
    canvas.drawLine(
      rect.bottomRight - Offset(cornerSize, 0),
      rect.bottomRight,
      corner,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(0, cornerSize),
      corner,
    );

    final scanLine = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF35D982).withValues(alpha: 0.96),
          Colors.transparent,
        ],
        begin: mode == ScannerFrameMode.qr
            ? Alignment.topCenter
            : Alignment.centerLeft,
        end: mode == ScannerFrameMode.qr
            ? Alignment.bottomCenter
            : Alignment.centerRight,
      ).createShader(rect)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    if (mode == ScannerFrameMode.qr) {
      final x = rect.left + rect.width * progress;
      canvas.drawLine(
          Offset(x, rect.top + 10), Offset(x, rect.bottom - 10), scanLine);
    } else {
      final y = rect.top + rect.height * progress;
      canvas.drawLine(
          Offset(rect.left + 10, y), Offset(rect.right - 10, y), scanLine);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Post-scan overlays
// ---------------------------------------------------------------------------

class _ScanSuccessOverlay extends StatelessWidget {
  const _ScanSuccessOverlay({
    required this.data,
    required this.onContinue,
    required this.onRescan,
  });

  final ParsedBillData data;
  final VoidCallback onContinue;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: Colors.greenAccent),
            const SizedBox(height: 16),
            Text(
              data.hasPixCode ? 'PIX detectado!' : 'Boleto detectado!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Continuar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRescan,
              child: const Text(
                'Escanear novamente',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanErrorOverlay extends StatelessWidget {
  const _ScanErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
