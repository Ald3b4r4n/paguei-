import 'package:flutter/material.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// Lottie-ready premium empty state widget.
///
/// Architecture: tries to render a [LottieAnimation] (passed as [animation])
/// if provided, otherwise falls back to the [fallbackIcon]. This keeps the
/// component Lottie-agnostic so it compiles without the lottie package being
/// required and allows gradual adoption.
///
/// ## Usage
///
/// ```dart
/// // With Lottie (when you have the asset):
/// EmptyStateWidget(
///   animation: Lottie.asset('assets/lottie/empty_bills.json'),
///   title: 'Nenhum boleto',
///   subtitle: 'Adicione seu primeiro boleto tocando em +',
///   action: FilledButton(onPressed: onAdd, child: Text('Adicionar')),
/// )
///
/// // Without Lottie (icon fallback):
/// EmptyStateWidget(
///   fallbackIcon: Icons.receipt_long_outlined,
///   title: 'Nenhum boleto',
///   subtitle: 'Adicione seu primeiro boleto tocando em +',
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    this.animation,
    this.fallbackIcon = Icons.inbox_outlined,
    this.iconSize = 72,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxxl,
      vertical: AppSpacing.xxl,
    ),
  });

  /// Optional Lottie widget (or any widget — e.g. `Lottie.asset(...)`).
  /// When non-null it is rendered instead of [fallbackIcon].
  final Widget? animation;

  /// Fallback icon shown when [animation] is null.
  final IconData fallbackIcon;

  /// Size of the fallback icon. Defaults to 72.
  final double iconSize;

  /// Primary empty-state label (bold, centred).
  final String title;

  /// Optional secondary description.
  final String? subtitle;

  /// Optional call-to-action widget (typically a [FilledButton]).
  final Widget? action;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Illustration ──────────────────────────────────────────────────
          if (animation != null)
            SizedBox(width: 180, height: 180, child: animation)
          else
            _FallbackIllustration(
              icon: fallbackIcon,
              iconSize: iconSize,
              color: colorScheme.primary,
            ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Title ──────────────────────────────────────────────────────────
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          // ── Subtitle ───────────────────────────────────────────────────────
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // ── CTA ────────────────────────────────────────────────────────────
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            action!,
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback illustration — circle with centred icon
// ---------------------------------------------------------------------------

class _FallbackIllustration extends StatelessWidget {
  const _FallbackIllustration({
    required this.icon,
    required this.iconSize,
    required this.color,
  });

  final IconData icon;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: iconSize * 1.8,
      height: iconSize * 1.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: color.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset empty-state variants — common screens
// ---------------------------------------------------------------------------

/// Empty state for the Bills list screen.
class BillsEmptyState extends StatelessWidget {
  const BillsEmptyState({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      fallbackIcon: Icons.receipt_long_outlined,
      title: 'Nenhum boleto',
      subtitle: 'Seus boletos aparecerão aqui.\nToque em + para adicionar.',
      action: onAdd != null
          ? FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar boleto'),
            )
          : null,
    );
  }
}

/// Empty state for the Funds list screen.
class FundsEmptyState extends StatelessWidget {
  const FundsEmptyState({super.key, this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      fallbackIcon: Icons.savings_outlined,
      title: 'Nenhuma reserva',
      subtitle:
          'Crie sua primeira reserva financeira para acompanhar o progresso.',
      action: onCreate != null
          ? FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Criar reserva'),
            )
          : null,
    );
  }
}

/// Empty state for the Transactions list screen.
class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      fallbackIcon: Icons.swap_horiz_outlined,
      title: 'Nenhuma transação',
      subtitle:
          'Registre receitas e despesas para\nacompanhar seu fluxo financeiro.',
      action: onAdd != null
          ? FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar transação'),
            )
          : null,
    );
  }
}

/// Empty state for search results.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, this.query});

  final String? query;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      fallbackIcon: Icons.search_off_outlined,
      title: 'Nenhum resultado',
      subtitle: query != null
          ? 'Nenhum item encontrado para "$query".'
          : 'Nenhum item corresponde à sua busca.',
    );
  }
}
