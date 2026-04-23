import 'package:flutter/material.dart';

/// Animated text widget that counts up (or down) to [value] when it changes.
///
/// Designed for displaying monetary balances and totals. The number animates
/// from its previous value to [value] over [duration] using a curved
/// [TweenAnimationBuilder], so the transition feels natural and premium.
///
/// ### Formatting
///
/// Supply a [formatter] to control how the number is displayed. Defaults to a
/// simple two-decimal fixed-point string (e.g. "1500.00"). For pt-BR currency
/// notation wrap with [CurrencyFormatter.format]:
///
/// ```dart
/// AnimatedBalanceText(
///   value: balance,
///   style: theme.textTheme.headlineMedium,
///   formatter: CurrencyFormatter.format,
/// )
/// ```
///
/// ### Accessibility
///
/// The underlying [Text] widget receives a `semanticsLabel` equal to the final
/// formatted string so screen-readers announce the correct value, not an
/// intermediate count-up state.
class AnimatedBalanceText extends StatelessWidget {
  const AnimatedBalanceText({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  /// The target numeric value.
  final double value;

  /// Text style applied to the animated label.
  final TextStyle? style;

  /// Optional formatter. Receives the intermediate animated double and should
  /// return the string to display. Defaults to `value.toStringAsFixed(2)`.
  final String Function(double)? formatter;

  /// Total animation duration. Defaults to 900 ms.
  final Duration duration;

  /// Animation curve. Defaults to [Curves.easeOutCubic].
  final Curve curve;

  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final resolvedFormatter = formatter ?? (v) => v.toStringAsFixed(2);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        final label = resolvedFormatter(animatedValue);
        return Text(
          label,
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          semanticsLabel: resolvedFormatter(value),
        );
      },
    );
  }
}

/// A variant that also fades-in + slides up on first appearance, then
/// count-up animates on subsequent value changes.
///
/// Uses a combination of [AnimatedSwitcher] (for mount animation) and
/// [AnimatedBalanceText] (for value changes).
class AnimatedBalanceDisplay extends StatelessWidget {
  const AnimatedBalanceDisplay({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
  });

  final double value;
  final TextStyle? style;
  final String Function(double)? formatter;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: AnimatedBalanceText(
        key: ValueKey(value.sign), // only re-mount on sign flip
        value: value,
        style: style,
        formatter: formatter,
        duration: duration,
        textAlign: textAlign,
      ),
    );
  }
}
