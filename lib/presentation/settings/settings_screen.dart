import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/settings/providers/backup_provider.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// Main settings screen.
///
/// Acts as a navigation hub for all app configuration sub-screens:
/// - Notification preferences
/// - Backup & restore
/// - Export center (CSV)
///
/// Hidden feature: tap "Versão do App" 10 times to open the beta
/// diagnostics screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 10) {
      _versionTapCount = 0;
      context.push(AppRoutes.diagnostics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastBackupAsync = ref.watch(lastBackupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Data section ─────────────────────────────────────────────────
          _SectionHeader(label: 'Dados e Exportação'),
          _SettingsTile(
            leading: Icons.backup_outlined,
            title: 'Backup e Restauração',
            subtitle: lastBackupAsync.when(
              data: (date) => date == null
                  ? 'Nenhum backup realizado'
                  : 'Último: ${_formatDate(date)}',
              loading: () => 'Carregando…',
              error: (_, __) => 'Backup',
            ),
            onTap: () => context.push(AppRoutes.backupSettings),
          ),
          _SettingsTile(
            leading: Icons.table_chart_outlined,
            title: 'Exportar para CSV',
            subtitle: 'Transações, boletos, dívidas e relatórios',
            onTap: () => context.push(AppRoutes.exportCenter),
          ),
          const Divider(indent: AppSpacing.lg * 4),

          // ── Financial management section ───────────────────────────────────
          _SectionHeader(label: 'Financeiro'),
          _SettingsTile(
            leading: Icons.account_balance_outlined,
            title: 'Locais do dinheiro',
            subtitle: 'Carteira, bancos e dinheiro vivo',
            onTap: () => context.push(AppRoutes.accounts),
          ),
          _SettingsTile(
            leading: Icons.savings_outlined,
            title: 'Fundos & Metas',
            subtitle: 'Reservas de emergência e objetivos',
            onTap: () => context.push(AppRoutes.funds),
          ),
          _SettingsTile(
            leading: Icons.credit_card_outlined,
            title: 'Dívidas',
            subtitle: 'Acompanhar e quitar dívidas',
            onTap: () => context.push(AppRoutes.debts),
          ),
          const Divider(indent: AppSpacing.lg * 4),

          // ── Notifications section ─────────────────────────────────────────
          _SectionHeader(label: 'Notificações'),
          _SettingsTile(
            leading: Icons.notifications_outlined,
            title: 'Preferências de Notificação',
            subtitle: 'Lembretes de boletos, dívidas e metas',
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          const Divider(indent: AppSpacing.lg * 4),

          // ── Privacy section ───────────────────────────────────────────────
          _SectionHeader(label: 'Privacidade'),
          _SettingsTile(
            leading: Icons.privacy_tip_outlined,
            title: 'Coleta de Dados Anônimos',
            subtitle: 'Gerencie seu consentimento (LGPD)',
            onTap: () => context.push(AppRoutes.privacyConsent),
          ),
          const Divider(indent: AppSpacing.lg * 4),

          // ── About section ─────────────────────────────────────────────────
          _SectionHeader(label: 'Sobre'),
          _SettingsTile(
            leading: Icons.info_outline,
            title: 'Versão do App',
            subtitle: '1.0.0+1',
            // 10 taps unlock diagnostics
            onTap: _onVersionTap,
          ),
          _SettingsTile(
            leading: Icons.feedback_outlined,
            title: 'Enviar Feedback',
            subtitle: 'Bug, sugestão ou avaliação',
            onTap: () => context.push(AppRoutes.feedback),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.year}';
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(leading, size: 20, color: cs.onSurfaceVariant),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      ),
      trailing:
          onTap != null ? Icon(Icons.chevron_right, color: cs.outline) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
    );
  }
}
