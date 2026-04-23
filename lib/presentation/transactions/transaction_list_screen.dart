import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
      ),
      body: const SafeArea(
        bottom: false,
        child: Column(
          children: [
            _MonthSelector(),
            _MonthlySummaryHeader(),
            _FiltersBar(),
            Expanded(child: _TransactionList()),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const _AddTransactionFab(),
    );
  }
}

// ---------------------------------------------------------------------------

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime month = ref.watch(selectedMonthProvider);
    final label = DateFormat.yMMMM('pt_BR').format(month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mês anterior',
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).month = DateTime(
                month.year,
                month.month - 1,
              );
            },
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  textBaseline: TextBaseline.alphabetic,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo mês',
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).month = DateTime(
                month.year,
                month.month + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MonthlySummaryHeader extends ConsumerWidget {
  const _MonthlySummaryHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Money> incomeAsync = ref.watch(monthlyIncomeProvider);
    final AsyncValue<Money> expenseAsync = ref.watch(monthlyExpenseProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Entrou',
              valueAsync: incomeAsync,
              color: Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Theme.of(context).colorScheme.outline,
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Saiu',
              valueAsync: expenseAsync,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.valueAsync,
    required this.color,
  });

  final String label;
  final AsyncValue<Money> valueAsync;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        valueAsync.when(
          loading: () => const SizedBox(
            height: 16,
            width: 60,
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const Text('--'),
          data: (money) => Text(
            CurrencyFormatter.format(money.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _TypeFilterNotifier extends Notifier<TransactionType?> {
  @override
  TransactionType? build() => null;

  set type(TransactionType? value) => state = value;
}

final _selectedTypeFilterProvider =
    NotifierProvider<_TypeFilterNotifier, TransactionType?>(
  _TypeFilterNotifier.new,
);

class _FiltersBar extends ConsumerWidget {
  const _FiltersBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionType? selectedType =
        ref.watch(_selectedTypeFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            selected: selectedType == null,
            onTap: () =>
                ref.read(_selectedTypeFilterProvider.notifier).type = null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Receitas',
            selected: selectedType == TransactionType.income,
            onTap: () => ref.read(_selectedTypeFilterProvider.notifier).type =
                TransactionType.income,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Despesas',
            selected: selectedType == TransactionType.expense,
            onTap: () => ref.read(_selectedTypeFilterProvider.notifier).type =
                TransactionType.expense,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Transferências',
            selected: selectedType == TransactionType.transfer,
            onTap: () => ref.read(_selectedTypeFilterProvider.notifier).type =
                TransactionType.transfer,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
      onSelected: (_) => onTap(),
    );
  }
}

// ---------------------------------------------------------------------------

class _TransactionList extends ConsumerWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Transaction>> txnsAsync =
        ref.watch(monthlyTransactionsProvider);
    final TransactionType? typeFilter = ref.watch(_selectedTypeFilterProvider);

    return txnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (transactions) {
        final filtered = typeFilter != null
            ? transactions.where((t) => t.type == typeFilter).toList()
            : transactions;

        if (filtered.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _TransactionTile(transaction: filtered[index]);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isTransfer
        ? Theme.of(context).colorScheme.secondary
        : isExpense
            ? Colors.red
            : Colors.green;
    final prefix = isTransfer
        ? ''
        : isExpense
            ? '- '
            : '+ ';

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir transação?'),
            content: Text(
                'Tem certeza que deseja excluir "${transaction.description}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(transactionNotifierProvider.notifier)
            .deleteTransaction(transaction.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        child: ListTile(
          leading: _TypeIcon(type: transaction.type),
          title: Text(
            transaction.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            DateFormat.MMMd('pt_BR').format(transaction.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            '$prefix${CurrencyFormatter.format(transaction.amount.amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          onTap: () => context.push(
            '/transacoes/${transaction.id}/editar',
            extra: transaction,
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      TransactionType.income => (Icons.arrow_downward, Colors.green),
      TransactionType.expense => (Icons.arrow_upward, Colors.red),
      TransactionType.transfer => (
          Icons.swap_horiz,
          Theme.of(context).colorScheme.secondary
        ),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma transação neste mês',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para registrar',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AddTransactionFab extends StatelessWidget {
  const _AddTransactionFab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12, right: 4),
      child: FloatingActionButton.extended(
        heroTag: 'add_transaction',
        onPressed: () => context.push('/transacoes/nova'),
        icon: const Icon(Icons.add),
        label: const Text('Nova transação'),
      ),
    );
  }
}
