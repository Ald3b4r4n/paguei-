import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/funds/providers/funds_provider.dart';
import 'package:paguei/presentation/funds/widgets/fund_card.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/shared/widgets/loading_skeleton.dart';

class FundListScreen extends ConsumerWidget {
  const FundListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(fundsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundos e Reservas'),
      ),
      body: fundsAsync.when(
        loading: () => const _FundsLoading(),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (funds) =>
            funds.isEmpty ? const _EmptyState() : _FundsList(funds: funds),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.fundNew),
        icon: const Icon(Icons.add),
        label: const Text('Novo Fundo'),
      ),
    );
  }
}

class _FundsList extends ConsumerWidget {
  const _FundsList({required this.funds});

  final List<Fund> funds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(fundNotifierProvider.notifier);
    final totalSaved =
        funds.fold(Money.zero, (acc, f) => acc + f.currentAmount);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SummaryHeader(
            totalFunds: funds.length,
            totalSaved: totalSaved,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final fund = funds[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FundCard(
                    fund: fund,
                    animationDelay: Duration(milliseconds: 50 * index),
                    onTap: () {}, // Fund detail screen not yet implemented
                    onContribute: () => _showAmountDialog(context, fund,
                        isContribute: true,
                        onConfirm: (amount) =>
                            notifier.contribute(fund.id, amount)),
                    onWithdraw: () => _showAmountDialog(context, fund,
                        isContribute: false,
                        onConfirm: (amount) =>
                            notifier.withdraw(fund.id, amount)),
                    onDelete: () => _confirmDelete(context, fund, notifier),
                  ),
                );
              },
              childCount: funds.length,
            ),
          ),
        ),
      ],
    );
  }

  void _showAmountDialog(
    BuildContext context,
    Fund fund, {
    required bool isContribute,
    required void Function(Money) onConfirm,
  }) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isContribute
            ? 'Aportar em ${fund.name}'
            : 'Retirar de ${fund.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor (R\$)',
            prefixText: 'R\$ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final raw = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (raw != null && raw > 0) {
                onConfirm(Money.fromDouble(raw));
                Navigator.of(ctx).pop();
              }
            },
            child: Text(isContribute ? 'Aportar' : 'Retirar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Fund fund,
    FundNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir fundo'),
        content:
            Text('Excluir "${fund.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              notifier.deleteFund(fund.id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalFunds,
    required this.totalSaved,
  });

  final int totalFunds;
  final Money totalSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total guardado',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalSaved.amount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalFunds',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
              Text(
                totalFunds == 1 ? 'fundo' : 'fundos',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum fundo criado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua reserva de emergência ou metas de poupança',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FundsLoading extends StatelessWidget {
  const _FundsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const LoadingSkeletonCard(height: 140),
    );
  }
}
