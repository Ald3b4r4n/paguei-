import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/debts/providers/debts_provider.dart';
import 'package:paguei/presentation/funds/providers/funds_provider.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';

/// Summary / Reports tab — monthly overview plus debts and funds.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final expenseAsync = ref.watch(monthlyExpenseProvider);
    final fundsAsync = ref.watch(fundsStreamProvider);
    final debtsAsync = ref.watch(activeDebtsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.screenPaddingV,
        ),
        children: [
          // ── Monthly summary ─────────────────────────────────────────────
          Text(
            'Mês atual',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.arrow_downward,
                  iconColor: Colors.green,
                  label: 'Receitas',
                  valueAsync: incomeAsync,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.arrow_upward,
                  iconColor: Colors.red,
                  label: 'Despesas',
                  valueAsync: expenseAsync,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Funds ───────────────────────────────────────────────────────
          _SectionHeader(
            title: 'Fundos & Metas',
            onAction: () => context.push(AppRoutes.funds),
            actionLabel: 'Ver todos',
          ),
          const SizedBox(height: AppSpacing.sm),
          fundsAsync.when(
            data: (funds) {
              if (funds.isEmpty) {
                return _EmptyHint(
                  icon: Icons.savings_outlined,
                  message: 'Nenhum fundo criado.',
                  actionLabel: 'Criar fundo',
                  onAction: () => context.push(AppRoutes.fundNew),
                );
              }
              final total =
                  funds.fold<double>(0, (s, f) => s + f.currentAmount.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total guardado: ${CurrencyFormatter.format(total)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...funds.take(3).map(
                        (f) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                          child: _FundSummaryTile(fund: f),
                        ),
                      ),
                  if (funds.length > 3)
                    TextButton(
                      onPressed: () => context.push(AppRoutes.funds),
                      child: Text('Ver mais ${funds.length - 3} fundos'),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erro ao carregar fundos: $e'),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Debts ───────────────────────────────────────────────────────
          _SectionHeader(
            title: 'Dívidas Ativas',
            onAction: () => context.push(AppRoutes.debts),
            actionLabel: 'Ver todas',
          ),
          const SizedBox(height: AppSpacing.sm),
          debtsAsync.when(
            data: (debts) {
              if (debts.isEmpty) {
                return _EmptyHint(
                  icon: Icons.credit_card_off_outlined,
                  message: 'Nenhuma dívida ativa.',
                  actionLabel: 'Registrar dívida',
                  onAction: () => context.push(AppRoutes.debtNew),
                );
              }
              final totalOwed =
                  debts.fold<double>(0, (s, d) => s + d.remainingAmount.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total em aberto: ${CurrencyFormatter.format(totalOwed)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...debts.take(3).map(
                        (d) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.credit_card_outlined),
                          title: Text(d.creditorName),
                          trailing: Text(
                            CurrencyFormatter.format(d.remainingAmount.amount),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  if (debts.length > 3)
                    TextButton(
                      onPressed: () => context.push(AppRoutes.debts),
                      child: Text('Ver mais ${debts.length - 3} dívidas'),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erro ao carregar dívidas: $e'),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onAction,
    required this.actionLabel,
  });

  final String title;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueAsync,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final AsyncValue<Money> valueAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 4),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            valueAsync.when(
              data: (v) => Text(
                CurrencyFormatter.format(v.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 80,
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => const Text('—'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundSummaryTile extends StatelessWidget {
  const _FundSummaryTile({required this.fund});

  final Fund fund;

  @override
  Widget build(BuildContext context) {
    final progress = fund.targetAmount.amount > 0
        ? (fund.currentAmount.amount / fund.targetAmount.amount).clamp(0.0, 1.0)
        : 0.0;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.savings_outlined),
      title: Text(fund.name),
      subtitle: LinearProgressIndicator(value: progress),
      trailing: Text(
        '${(progress * 100).toInt()}%',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 32, color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
