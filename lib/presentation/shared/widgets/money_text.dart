import 'package:flutter/material.dart';
import 'package:paguei/domain/value_objects/money.dart';

/// Displays a [Money] value formatted in pt-BR (e.g. "R$ 1.234,56").
///
/// Positive values render in the theme's onSurface color by default.
/// Negative values render in the theme's error color.
/// Zero renders in the secondary label color.
///
/// Pass [style] to override the default text style.
/// Pass [positiveColor], [negativeColor], [zeroColor] for fine-grained control.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    super.key,
    this.style,
    this.positiveColor,
    this.negativeColor,
    this.zeroColor,
    this.showSign = false,
    this.compact = false,
  });

  final Money money;
  final TextStyle? style;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? zeroColor;

  /// Prepend "+" for positive values.
  final bool showSign;

  /// Use compact formatting (e.g. "R$ 1,2 mil") for large values.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _resolveColor(colorScheme);
    final effectiveStyle = (style ?? Theme.of(context).textTheme.bodyLarge)
        ?.copyWith(color: color);

    final text = _format();

    return Text(
      text,
      style: effectiveStyle,
    );
  }

  Color _resolveColor(ColorScheme scheme) {
    if (money.isNegative) return negativeColor ?? scheme.error;
    if (money.isZero) return zeroColor ?? scheme.onSurfaceVariant;
    return positiveColor ?? scheme.onSurface;
  }

  String _format() {
    final formatted = money.formatted();
    if (showSign && money.isPositive) return '+$formatted';
    return formatted;
  }
}
