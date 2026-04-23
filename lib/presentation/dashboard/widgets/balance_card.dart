import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/shared/widgets/loading_skeleton.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo disponível',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(summary.totalBalance.amount),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Entrou este mês',
                    amount: summary.monthlyIncome,
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF2E7D32),
                    growth: summary.incomeGrowthRate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'Saiu este mês',
                    amount: summary.monthlyExpense,
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFFC62828),
                    growth: summary.expenseGrowthRate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class BalanceCardLoading extends StatelessWidget {
  const BalanceCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(width: 80, height: 14),
            SizedBox(height: 12),
            LoadingSkeleton(height: 36, width: double.infinity),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: LoadingSkeletonCard(height: 60)),
                SizedBox(width: 12),
                Expanded(child: LoadingSkeletonCard(height: 60)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.growth,
  });

  final String label;
  final Money amount;
  final IconData icon;
  final Color color;
  final double? growth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onPrimaryContainer
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          if (growth != null) ...[
            const SizedBox(height: 2),
            Text(
              '${growth! >= 0 ? '+' : ''}${(growth! * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: growth! >= 0
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
