import 'package:flutter/material.dart';
import 'package:paguei/domain/entities/bill_status.dart';

class BillStatusChip extends StatelessWidget {
  const BillStatusChip({super.key, required this.status});

  final BillStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, textColor) = _colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  static (Color, Color) _colorsFor(BillStatus status) => switch (status) {
        BillStatus.pending => (
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100)
          ),
        BillStatus.overdue => (
            const Color(0xFFFFEBEE),
            const Color(0xFFC62828)
          ),
        BillStatus.paid => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
        BillStatus.cancelled => (
            const Color(0xFFF5F5F5),
            const Color(0xFF616161)
          ),
      };
}
