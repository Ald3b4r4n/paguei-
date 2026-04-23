import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/shared/widgets/loading_skeleton.dart';

class BillsSummaryCard extends StatelessWidget {
  const BillsSummaryCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Boletos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (summary.hasOverdueBills) ...[
                  const SizedBox(width: 8),
                  _OverdueBadge(count: summary.overdueBillsCount),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BillsMetric(
                    label: 'Pendente',
                    amount: summary.pendingBillsTotal,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BillsMetric(
                    label: 'Vencido',
                    amount: summary.overdueBillsTotal,
                    color: const Color(0xFFC62828),
                    isAlert: summary.hasOverdueBills,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class BillsSummaryCardLoading extends StatelessWidget {
  const BillsSummaryCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingSkeletonCard(height: 120);
  }
}

class _BillsMetric extends StatelessWidget {
  const _BillsMetric({
    required this.label,
    required this.amount,
    required this.color,
    this.isAlert = false,
  });

  final String label;
  final Money amount;
  final Color color;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            isAlert ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onError,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
