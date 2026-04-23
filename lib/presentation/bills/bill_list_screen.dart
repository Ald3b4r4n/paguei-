import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/bills/widgets/bill_card.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/scanner/bill_scan_screen.dart';

class BillListScreen extends ConsumerWidget {
  const BillListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Boletos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendentes'),
              Tab(text: 'Vencidos'),
              Tab(text: 'Pagos'),
            ],
          ),
        ),
        body: const Column(
          children: [
            _BillCaptureActions(),
            Expanded(
              child: TabBarView(
                children: [
                  _BillTab(status: _TabStatus.pending),
                  _BillTab(status: _TabStatus.overdue),
                  _BillTab(status: _TabStatus.paid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillCaptureActions extends StatelessWidget {
  const _BillCaptureActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _CaptureButton(
            icon: Icons.qr_code_scanner_outlined,
            label: 'Escanear QRCode PIX',
            filled: true,
            onPressed: () => context.push(AppRoutes.billScan),
          ),
          _CaptureButton(
            icon: Icons.document_scanner_outlined,
            label: 'Escanear Código de Barras',
            filled: true,
            onPressed: () => context.push(AppRoutes.billScan),
          ),
          _CaptureButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Importar PDF',
            onPressed: () => context.push(
              AppRoutes.billScan,
              extra: BillScanInitialAction.importPdf,
            ),
          ),
          _CaptureButton(
            icon: Icons.image_search_outlined,
            label: 'Ler Imagem',
            onPressed: () => context.push(
              AppRoutes.billScan,
              extra: BillScanInitialAction.importImage,
            ),
          ),
          _CaptureButton(
            icon: Icons.edit_note_outlined,
            label: 'Inserir Manualmente',
            onPressed: () => context.push(AppRoutes.billNew),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final child = Text(
      label,
      maxLines: compact ? 2 : 1,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
    );

    if (filled) {
      return SizedBox(
        width: compact ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: child,
        ),
      );
    }

    return SizedBox(
      width: compact ? double.infinity : null,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      ),
    );
  }
}

enum _TabStatus { pending, overdue, paid }

class _BillTab extends ConsumerWidget {
  const _BillTab({required this.status});

  final _TabStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBillsAsync = ref.watch(allBillsProvider);

    return allBillsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (bills) {
        final filtered = _filterBills(bills, status);
        if (filtered.isEmpty) {
          return _EmptyState(status: status);
        }

        return Column(
          children: [
            if (status == _TabStatus.pending || status == _TabStatus.overdue)
              _SummaryHeader(bills: filtered),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 96, top: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final bill = filtered[index];
                  return BillCard(
                    bill: bill,
                    onMarkAsPaid: bill.isPaid || bill.isCancelled
                        ? null
                        : () => _markAsPaid(context, ref, bill),
                    onDelete: () => _deleteBill(ref, bill.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Bill> _filterBills(List<Bill> bills, _TabStatus status) {
    return switch (status) {
      _TabStatus.pending =>
        bills.where((b) => b.effectiveStatus == BillStatus.pending).toList(),
      _TabStatus.overdue =>
        bills.where((b) => b.effectiveStatus == BillStatus.overdue).toList(),
      _TabStatus.paid => bills.where((b) => b.isPaid).toList(),
    };
  }

  Future<void> _markAsPaid(
      BuildContext context, WidgetRef ref, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Pago'),
        content: Text(
          'Confirma o pagamento de "${bill.title}" no valor de ${CurrencyFormatter.format(bill.amount.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref.read(billNotifierProvider.notifier).markAsPaid(id: bill.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao marcar como pago')),
          );
        }
      }
    }
  }

  Future<void> _deleteBill(WidgetRef ref, String id) async {
    await ref.read(billNotifierProvider.notifier).deleteBill(id);
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    final total = bills.fold(Money.zero, (acc, b) => acc + b.amount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${bills.length} ${bills.length == 1 ? 'boleto' : 'boletos'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Total: ${CurrencyFormatter.format(total.amount)}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});

  final _TabStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (status) {
      _TabStatus.pending => (
          Icons.check_circle_outline,
          'Nenhum boleto pendente'
        ),
      _TabStatus.overdue => (Icons.celebration, 'Nenhum boleto vencido!'),
      _TabStatus.paid => (Icons.receipt_long, 'Nenhum boleto pago'),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
