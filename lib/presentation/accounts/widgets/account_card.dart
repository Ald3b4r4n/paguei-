import 'package:flutter/material.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/presentation/shared/widgets/money_text.dart';

/// Card widget displaying an [Account] summary.
///
/// Tapping the card triggers [onTap].
/// Long-pressing triggers [onLongPress] (used for contextual actions).
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onLongPress,
  });

  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountColor = Color(account.color);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accountColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _AccountIcon(color: accountColor, icon: account.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      account.type.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    account.currentBalance,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (account.isArchived)
                    Chip(
                      label: Text(
                        'Arquivada',
                        style: theme.textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon({required this.color, required this.icon});

  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(
        _iconData(icon),
        color: color,
        size: 22,
      ),
    );
  }

  IconData _iconData(String name) {
    return switch (name) {
      'account_balance' => Icons.account_balance,
      'savings' => Icons.savings,
      'wallet' => Icons.account_balance_wallet,
      'trending_up' => Icons.trending_up,
      _ => Icons.account_balance,
    };
  }
}
