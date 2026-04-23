import 'package:flutter/material.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/core/utils/date_formatter.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'bill_status_chip.dart';

class BillCard extends StatelessWidget {
  const BillCard({
    super.key,
    required this.bill,
    this.onTap,
    this.onMarkAsPaid,
    this.onDelete,
  });

  final Bill bill;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = bill.effectiveStatus;

    return Dismissible(
      key: Key('bill-${bill.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        return _confirmDelete(context);
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatusIcon(status: effectiveStatus),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: _dueDateColor(context, effectiveStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatShort(bill.dueDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      _dueDateColor(context, effectiveStatus),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(bill.amount.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    BillStatusChip(status: effectiveStatus),
                  ],
                ),
                if (onMarkAsPaid != null &&
                    effectiveStatus != BillStatus.paid &&
                    effectiveStatus != BillStatus.cancelled) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Marcar como pago',
                    onPressed: onMarkAsPaid,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _dueDateColor(BuildContext context, BillStatus status) {
    return status == BillStatus.overdue
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Boleto'),
        content: Text('Deseja excluir "${bill.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final BillStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      BillStatus.pending => (Icons.receipt_long, const Color(0xFFE65100)),
      BillStatus.overdue => (Icons.warning_amber, Colors.red),
      BillStatus.paid => (Icons.check_circle, Colors.green),
      BillStatus.cancelled => (Icons.cancel, Colors.grey),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
