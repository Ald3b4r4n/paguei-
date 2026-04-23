import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/core/analytics/analytics_providers.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// LGPD-compliant consent dialog shown on first launch.
///
/// Must be shown before any analytics tracking begins.
/// The dialog is non-dismissible (user must make an explicit choice).
///
/// Usage: call [AnalyticsConsentDialog.showIfNeeded] from the root widget.
class AnalyticsConsentDialog extends ConsumerWidget {
  const AnalyticsConsentDialog({super.key});

  /// Shows the dialog if the user has not yet been asked for consent.
  ///
  /// Safe to call every startup — returns immediately if already asked.
  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final consentAsync = ref.read(analyticsConsentProvider);
    final consent = consentAsync.asData?.value;
    if (consent == null || consent.hasBeenAsked) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AnalyticsConsentDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Melhore o Paguei?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podemos coletar dados anônimos de uso para melhorar o aplicativo?',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulletItem('Nenhum dado pessoal (nome, CPF, saldo)'),
                _BulletItem('Nenhum dado financeiro'),
                _BulletItem('Apenas eventos de uso (ex: "backup criado")'),
                _BulletItem('Você pode revogar a qualquer momento'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Conforme a LGPD (Lei 13.709/2018), você tem controle total '
            'sobre seus dados.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(analyticsConsentProvider.notifier).deny();
            Navigator.pop(context);
          },
          child: const Text('Não, obrigado'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(analyticsConsentProvider.notifier).grant();
            Navigator.pop(context);
          },
          child: const Text('Permitir'),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
