import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paguei/core/analytics/analytics_event.dart';
import 'package:paguei/core/analytics/analytics_providers.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Feedback hub: report a bug, suggest a feature, or rate the app.
///
/// Uses [url_launcher] to open e-mail and store URLs.
/// No external feedback SDK required — keeps the APK lean.
///
/// ## Customisation
///
/// Update [_supportEmail] and [_storeUrl] with real values before release.
/// The mailto: links pre-fill subject and body with device context.
class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  // ── Constants ─────────────────────────────────────────────────────────────

  static const _supportEmail = 'rafasouzacruz@gmail.com';
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.paguei.app';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Feedback'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.screenPaddingV,
        ),
        children: [
          Text(
            'Sua opinião ajuda a melhorar o Paguei? para todos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Bug report ────────────────────────────────────────────────
          _FeedbackCard(
            icon: Icons.bug_report_outlined,
            iconColor: cs.error,
            title: 'Reportar um Bug',
            description:
                'Encontrou algo que não funciona? Nos conte o que aconteceu.',
            actionLabel: 'Enviar por E-mail',
            onAction: () {
              ref.trackEvent(
                const FeedbackSubmittedEvent(feedbackType: 'bug_report'),
              );
              _launchEmailDraft(
                context,
                subject: '[Paguei?] Bug Report',
                type: _FeedbackType.bug,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Feature request ───────────────────────────────────────────
          _FeedbackCard(
            icon: Icons.lightbulb_outlined,
            iconColor: Colors.amber,
            title: 'Sugerir Funcionalidade',
            description:
                'Tem uma ideia que tornaria o app melhor? Adoramos ouvir.',
            actionLabel: 'Enviar Sugestão',
            onAction: () {
              ref.trackEvent(
                const FeedbackSubmittedEvent(feedbackType: 'feature_request'),
              );
              _launchEmailDraft(
                context,
                subject: '[Paguei?] Sugestão de Funcionalidade',
                type: _FeedbackType.feature,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Rate app ──────────────────────────────────────────────────
          _FeedbackCard(
            icon: Icons.star_outline_rounded,
            iconColor: Colors.orange,
            title: 'Avaliar o App',
            description:
                'Gostou do Paguei?? Uma avaliação na loja faz grande diferença!',
            actionLabel: 'Avaliar na Play Store',
            onAction: () {
              ref.trackEvent(
                const FeedbackSubmittedEvent(feedbackType: 'rating'),
              );
              _launchStore(context);
            },
          ),

          const SizedBox(height: AppSpacing.huge),

          // ── Privacy note ──────────────────────────────────────────────
          Text(
            '💡 Ao enviar por e-mail, apenas o conteúdo que você '
            'escrever é enviado. Nenhum dado do app é incluído '
            'automaticamente.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Launchers ─────────────────────────────────────────────────────────────

  static Future<void> _launchEmailDraft(
    BuildContext context, {
    required String subject,
    required _FeedbackType type,
  }) async {
    final diagnostics = await _collectDiagnostics();
    final body = switch (type) {
      _FeedbackType.bug => _bugBody(diagnostics),
      _FeedbackType.feature => _featureBody(diagnostics),
    };
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o e-mail.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<_FeedbackDiagnostics> _collectDiagnostics() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    if (!Platform.isAndroid) {
      return _FeedbackDiagnostics(
        appVersion: appVersion,
        androidVersion: Platform.operatingSystemVersion,
        deviceModel: 'Não disponível nesta plataforma',
      );
    }

    try {
      final android = await DeviceInfoPlugin().androidInfo;
      return _FeedbackDiagnostics(
        appVersion: appVersion,
        androidVersion:
            'Android ${android.version.release} (SDK ${android.version.sdkInt})',
        deviceModel: '${android.manufacturer} ${android.model}',
      );
    } catch (_) {
      return _FeedbackDiagnostics(
        appVersion: appVersion,
        androidVersion: Platform.operatingSystemVersion,
        deviceModel: 'Não disponível',
      );
    }
  }

  static String _bugBody(_FeedbackDiagnostics d) {
    return '''
Mensagem do usuário:


Passos para reproduzir:
1.
2.
3.

Comportamento esperado:


Comportamento observado:


Contexto técnico:
- App version: ${d.appVersion}
- Android version: ${d.androidVersion}
- Device model: ${d.deviceModel}
''';
  }

  static String _featureBody(_FeedbackDiagnostics d) {
    return '''
Sugestão:


Problema que resolve:


Como imagino usando:


Prioridade para mim:


Contexto técnico:
- App version: ${d.appVersion}
- Android version: ${d.androidVersion}
- Device model: ${d.deviceModel}
''';
  }

  static Future<void> _launchStore(BuildContext context) async {
    final uri = Uri.parse(_storeUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir a loja.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

enum _FeedbackType { bug, feature }

final class _FeedbackDiagnostics {
  const _FeedbackDiagnostics({
    required this.appVersion,
    required this.androidVersion,
    required this.deviceModel,
  });

  final String appVersion;
  final String androidVersion;
  final String deviceModel;
}

// ---------------------------------------------------------------------------
// Privacy consent screen (stub — links to analytics settings)
// ---------------------------------------------------------------------------

/// Manages the user's LGPD analytics consent.
class PrivacyConsentScreen extends ConsumerWidget {
  const PrivacyConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentAsync = ref.watch(analyticsConsentProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade'),
        centerTitle: true,
      ),
      body: consentAsync.when(
        data: (consent) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Coleta de Dados Anônimos',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Coletamos apenas eventos de uso anônimos (ex: "backup criado", '
              '"boleto pago") para melhorar o aplicativo. Nenhum dado pessoal '
              'ou financeiro é coletado.\n\n'
              'Você pode alterar essa preferência a qualquer momento. '
              'Conforme a LGPD (Lei 13.709/2018), seu consentimento pode '
              'ser revogado sem penalidade.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SwitchListTile(
              value: consent.isGranted,
              onChanged: (v) {
                if (v) {
                  ref.read(analyticsConsentProvider.notifier).grant();
                } else {
                  ref.read(analyticsConsentProvider.notifier).deny();
                }
              },
              title: const Text('Permitir coleta de dados anônimos'),
              subtitle: Text(
                consent.isGranted
                    ? 'Ativado — obrigado por contribuir!'
                    : 'Desativado',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              secondary: Icon(
                consent.isGranted ? Icons.analytics : Icons.analytics_outlined,
                color: consent.isGranted ? cs.primary : cs.outline,
              ),
            ),
            if (consent.grantedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Última alteração: ${_fmt(consent.grantedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.year} ${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// _FeedbackCard
// ---------------------------------------------------------------------------

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: iconColor,
                  side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
