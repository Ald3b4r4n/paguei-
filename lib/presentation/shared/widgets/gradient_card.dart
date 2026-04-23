import 'package:flutter/material.dart';
import 'package:paguei/presentation/theme/app_colors.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// A premium card with a [LinearGradient] background.
///
/// Defaults to [AppGradients.primaryVertical] (dark green → mid green) which
/// works for hero/balance cards. Supply a different [gradient] for semantic
/// variants (success, warning, error).
///
/// The [elevation] creates a coloured shadow that matches the gradient's
/// primary hue, giving the card depth without harsh grey shadows.
///
/// ## Usage
///
/// ```dart
/// GradientCard(
///   gradient: AppGradients.success,
///   child: SomeContent(),
/// )
/// ```
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.shadowColor,
    this.borderRadius,
    this.elevation = 4,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;

  /// The gradient to paint. Defaults to [AppGradients.primaryVertical] in
  /// light mode and [AppGradients.primaryVerticalDark] in dark mode when null.
  final LinearGradient? gradient;

  /// Tinted shadow colour. Auto-derived from gradient if not set.
  final Color? shadowColor;

  final BorderRadius? borderRadius;

  /// Material elevation that drives the shadow.
  final double elevation;

  final EdgeInsets padding;
  final EdgeInsets margin;

  /// Optional tap callback. When set the card gets an InkWell splash.
  final VoidCallback? onTap;

  /// Accessibility label passed to [Semantics].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedGradient = gradient ??
        (isDark
            ? AppGradients.primaryVerticalDark
            : AppGradients.primaryVertical);

    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);

    // Derive a tinted shadow from the gradient's first stop.
    final resolvedShadow =
        shadowColor ?? resolvedGradient.colors.first.withValues(alpha: 0.35);

    return Semantics(
      label: semanticLabel,
      container: semanticLabel != null,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          gradient: resolvedGradient,
          borderRadius: resolvedRadius,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: resolvedShadow,
                    blurRadius: elevation * 3,
                    offset: Offset(0, elevation),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: resolvedRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: resolvedRadius,
            splashColor: Colors.white10,
            highlightColor: Colors.white10,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience variants
// ---------------------------------------------------------------------------

/// A [GradientCard] pre-styled for the dashboard hero / balance card.
class HeroBalanceCard extends StatelessWidget {
  const HeroBalanceCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GradientCard(
      gradient: isDark ? AppGradients.heroDark : AppGradients.heroLight,
      elevation: 6,
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      semanticLabel: 'Saldo principal',
      child: child,
    );
  }
}

/// A [GradientCard] for success/income tiles.
class SuccessGradientCard extends StatelessWidget {
  const SuccessGradientCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.success,
      elevation: 3,
      onTap: onTap,
      child: child,
    );
  }
}

/// A [GradientCard] for warning/expense tiles.
class WarningGradientCard extends StatelessWidget {
  const WarningGradientCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.warning,
      elevation: 3,
      onTap: onTap,
      child: child,
    );
  }
}
