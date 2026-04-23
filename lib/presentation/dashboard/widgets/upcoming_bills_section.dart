import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/core/utils/date_formatter.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/presentation/bills/widgets/bill_status_chip.dart';
import 'package:paguei/presentation/shared/widgets/loading_skeleton.dart';

class UpcomingBillsSection extends StatelessWidget {
  const UpcomingBillsSection({super.key, required this.bills});

  final List<BillSummary> bills;

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return _EmptyUpcoming();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Próximos 7 dias',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...bills.asMap().entries.map(
              (e) => _UpcomingBillTile(
                bill: e.value,
                delay: (e.key * 50).ms,
              ),
            ),
      ],
    );
  }
}

class UpcomingBillsSectionLoading extends StatelessWidget {
  const UpcomingBillsSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: LoadingSkeleton(width: 120, height: 16),
        ),
        const LoadingSkeletonCard(),
        const LoadingSkeletonCard(),
      ],
    );
  }
}

class _UpcomingBillTile extends StatelessWidget {
  const _UpcomingBillTile({required this.bill, required this.delay});

  final BillSummary bill;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final isDueToday = _isDueToday(bill.dueDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDueToday
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDueToday ? Icons.warning_amber_rounded : Icons.receipt_long,
            size: 20,
            color: isDueToday
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          bill.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isDueToday
              ? 'Vence hoje!'
              : 'Vence em ${DateFormatter.formatShort(bill.dueDate)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDueToday
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(bill.amount.amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            BillStatusChip(status: bill.effectiveStatus),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: delay)
        .slideX(begin: 0.05, end: 0, delay: delay);
  }

  bool _isDueToday(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}

class _EmptyUpcoming extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Text(
            'Nenhum boleto vencendo nos próximos 7 dias',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
