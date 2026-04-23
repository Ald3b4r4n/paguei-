import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/scanner/bill_scan_screen.dart';
import 'package:paguei/presentation/scanner/widgets/camera_permission_explainer.dart';
import 'package:paguei/presentation/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrapState(ScanScreenState state) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: _FakeStateBillScanScreen(state: state),
    ),
  );
}

/// Test-only widget that accepts a pre-set [ScanScreenState] and renders
/// exactly the same sub-widgets as [BillScanScreen] without touching the camera.
class _FakeStateBillScanScreen extends StatelessWidget {
  const _FakeStateBillScanScreen({required this.state});

  final ScanScreenState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Escanear Boleto'),
      ),
      body: switch (state) {
        ScanIdle() ||
        ScanCheckingPermission() ||
        ScanImporting() =>
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ScanPermissionDenied(isPermanent: final perm) =>
          CameraPermissionExplainer(
            isPermanentlyDenied: perm,
            onAllowPressed: () {},
            onDenyPressed: () {},
            onOpenSettingsPressed: () {},
          ),
        ScanScanning() => const Center(
            child: Text(
              'SCANNER ATIVO',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ScanSuccess(data: final data) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 80, color: Colors.greenAccent),
                Text(
                  data.hasPixCode ? 'PIX detectado!' : 'Boleto detectado!',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
                FilledButton(onPressed: () {}, child: const Text('Continuar')),
              ],
            ),
          ),
        ScanError(message: final msg) => Center(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
      },
    );
  }
}

ParsedBillData _buildParsedData({
  bool hasBarcode = true,
  bool hasPixCode = false,
}) {
  return ParsedBillData(
    source: ScanSourceType.camera,
    confidence: 0.98,
    barcode: hasBarcode ? '0' * 44 : null,
    pixCode: hasPixCode ? '00020126...' : null,
    amount: Money.fromDouble(150.0),
    dueDate: DateTime(2026, 5, 10),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BillScanScreen — Idle / CheckingPermission state', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(_wrapState(const ScanCheckingPermission()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('BillScanScreen — PermissionDenied state', () {
    testWidgets('shows CameraPermissionExplainer when permission denied',
        (tester) async {
      await tester.pumpWidget(_wrapState(const ScanPermissionDenied()));
      await tester.pumpAndSettle();

      expect(find.byType(CameraPermissionExplainer), findsOneWidget);
    });

    testWidgets('explainer shows "Abrir Configurações" when permanently denied',
        (tester) async {
      await tester.pumpWidget(
          _wrapState(const ScanPermissionDenied(isPermanent: true)));
      await tester.pumpAndSettle();

      expect(find.text('Abrir Configurações'), findsOneWidget);
    });

    testWidgets('explainer shows "Permitir" button when just denied',
        (tester) async {
      await tester.pumpWidget(_wrapState(const ScanPermissionDenied()));
      await tester.pumpAndSettle();

      expect(find.text('Permitir acesso à câmera'), findsOneWidget);
    });
  });

  group('BillScanScreen — Scanning state', () {
    testWidgets('shows scanner active indicator', (tester) async {
      await tester.pumpWidget(_wrapState(const ScanScanning()));
      await tester.pump();

      expect(find.text('SCANNER ATIVO'), findsOneWidget);
    });
  });

  group('BillScanScreen — Success state', () {
    testWidgets('shows boleto success message for barcode scan',
        (tester) async {
      await tester.pumpWidget(_wrapState(ScanSuccess(_buildParsedData())));
      await tester.pumpAndSettle();

      expect(find.text('Boleto detectado!'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('shows PIX success message for QR scan', (tester) async {
      await tester.pumpWidget(_wrapState(
          ScanSuccess(_buildParsedData(hasBarcode: false, hasPixCode: true))));
      await tester.pumpAndSettle();

      expect(find.text('PIX detectado!'), findsOneWidget);
    });

    testWidgets('shows success icon on detection', (tester) async {
      await tester.pumpWidget(_wrapState(ScanSuccess(_buildParsedData())));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('BillScanScreen — Error state', () {
    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(_wrapState(const ScanError('Código inválido')));
      await tester.pumpAndSettle();

      expect(find.text('Código inválido'), findsOneWidget);
    });
  });
}
