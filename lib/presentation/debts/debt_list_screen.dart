import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/debts/providers/debts_provider.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// Screen listing all debts with payment registration support.
class DebtListScreen extends ConsumerWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(allDebtsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dívidas'),
        centerTitle: true,
      ),
      body: debtsAsync.when(
        data: (debts) {
          if (debts.isEmpty) return const _EmptyState();
          final activeDebts =
              debts.where((d) => d.status == DebtStatus.active).toList();
          final paidDebts =
              debts.where((d) => d.status != DebtStatus.active).toList();
          final totalRemaining = activeDebts.fold<double>(
            0,
            (sum, d) => sum + d.remainingAmount.amount,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TotalHeader(totalRemaining: totalRemaining),
              ),
              if (activeDebts.isNotEmpty) ...[
                const _SectionHeader(label: 'ATIVAS'),
                SliverList.builder(
                  itemCount: activeDebts.length,
                  itemBuilder: (context, i) => _DebtCard(
                    debt: activeDebts[i],
                    onPayment: () =>
                        _showPaymentDialog(context, ref, activeDebts[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, activeDebts[i]),
                  ),
                ),
              ],
              if (paidDebts.isNotEmpty) ...[
                const _SectionHeader(label: 'QUITADAS'),
                SliverList.builder(
                  itemCount: paidDebts.length,
                  itemBuilder: (context, i) => _DebtCard(
                    debt: paidDebts[i],
                    onDelete: () => _confirmDelete(context, ref, paidDebts[i]),
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_debt',
        onPressed: () => context.push(AppRoutes.debtNew),
        icon: const Icon(Icons.add),
        label: const Text('Nova Dívida'),
      ),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Debt debt,
  ) async {
    final controller = TextEditingController(
      text: debt.installmentAmount?.amount.toStringAsFixed(2) ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar pagamento\n${debt.creditorName}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor pago (R\$)',
            prefixText: 'R\$ ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final value = double.tryParse(
      controller.text.replaceAll(',', '.'),
    );
    if (value == null || value <= 0) return;

    try {
      await ref
          .read(debtNotifierProvider.notifier)
          .registerPayment(debt.id, Money.fromDouble(value));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento registrado!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Debt debt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir dívida?'),
        content: Text(
            'A dívida com ${debt.creditorName} será removida permanentemente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(debtNotifierProvider.notifier).deleteDebt(debt.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.totalRemaining});

  final double totalRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total em aberto',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalRemaining),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    this.onPayment,
    required this.onDelete,
  });

  final Debt debt;
  final VoidCallback? onPayment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = debt.status == DebtStatus.active;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    debt.creditorName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (isActive) ...[
                  IconButton(
                    icon: const Icon(Icons.payments_outlined),
                    tooltip: 'Registrar pagamento',
                    onPressed: onPayment,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo restante',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      CurrencyFormatter.format(debt.remainingAmount.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      CurrencyFormatter.format(debt.totalAmount.amount),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            if (debt.installments != null) ...[
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: debt.progressRate,
                backgroundColor: cs.surfaceContainerHighest,
                color: isActive ? cs.primary : cs.secondary,
              ),
              const SizedBox(height: 2),
              Text(
                '${debt.installmentsPaid}/${debt.installments} parcelas',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.credit_card_off_outlined,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text('Nenhuma dívida cadastrada', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Registre dívidas para acompanhar\nos pagamentos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
