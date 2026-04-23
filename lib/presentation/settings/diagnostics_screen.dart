import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/core/constants/app_constants.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/core/logging/app_logger.dart';
import 'package:paguei/core/logging/buffered_logger.dart';
import 'package:paguei/presentation/notifications/providers/notifications_provider.dart';
import 'package:paguei/presentation/settings/providers/backup_provider.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// Async data providers for diagnostics
// ---------------------------------------------------------------------------

final _pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  final datasource = ref.watch(notificationDatasourceProvider);
  final ids = await datasource.pendingIds();
  return ids.length;
});

// ---------------------------------------------------------------------------
// DiagnosticsScreen
// ---------------------------------------------------------------------------

/// Hidden beta diagnostics screen.
///
/// Access: tap the "Versão do App" tile in SettingsScreen 10 times.
///
/// Shows sanitised system state — no PII, no raw financial data.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(_pendingNotificationCountProvider);
    final lastBackupAsync = ref.watch(lastBackupProvider);
    final bufferedLogger = ref.watch(bufferedLoggerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico Beta'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar diagnóstico',
            onPressed: () => _copyDiagnostics(
              context,
              pendingAsync: pendingAsync,
              lastBackupAsync: lastBackupAsync,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.screenPaddingV,
        ),
        children: [
          // ── App info ──────────────────────────────────────────────────
          _DiagSection(title: 'Aplicativo', children: [
            _DiagRow('Versão', '1.0.0+1'),
            _DiagRow('Build', 'release'),
            _DiagRow('DB Schema', 'v${AppConstants.databaseSchemaVersion}'),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // ── Notifications ──────────────────────────────────────────────
          _DiagSection(title: 'Notificações', children: [
            pendingAsync.when(
              data: (count) => _DiagRow('Agendadas', '$count'),
              loading: () => const _DiagRow('Agendadas', '…'),
              error: (e, _) => _DiagRow('Agendadas', 'erro: $e'),
            ),
            _DiagRow('Máximo', '${AppConstants.maxNotificationsScheduled}'),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // ── Backup ────────────────────────────────────────────────────
          _DiagSection(title: 'Backup', children: [
            lastBackupAsync.when(
              data: (date) => _DiagRow(
                'Último backup',
                date?.toIso8601String() ?? 'nunca',
              ),
              loading: () => const _DiagRow('Último backup', '…'),
              error: (e, _) => _DiagRow('Último backup', 'erro: $e'),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // ── Recent logs ────────────────────────────────────────────────
          _DiagSection(
            title: 'Últimos Logs (${bufferedLogger.entries.length})',
            children: [
              _LogView(entries: bufferedLogger.entries),
            ],
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  void _copyDiagnostics(
    BuildContext context, {
    required AsyncValue<int> pendingAsync,
    required AsyncValue<DateTime?> lastBackupAsync,
  }) {
    final sb = StringBuffer();
    sb.writeln('=== Paguei Diagnóstico ===');
    sb.writeln('Versão: 1.0.0+1');
    sb.writeln('DB Schema: v${AppConstants.databaseSchemaVersion}');
    sb.writeln(
        'Notificações agendadas: ${pendingAsync.asData?.value ?? 'N/A'}');
    sb.writeln(
        'Último backup: ${lastBackupAsync.asData?.value?.toIso8601String() ?? 'nunca'}');
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnóstico copiado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _DiagSection extends StatelessWidget {
  const _DiagSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: SelectableText(
        value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView({required this.entries});

  final List<LogEntry> entries;

  static const _levelColors = {
    LogLevel.debug: Colors.grey,
    LogLevel.info: Colors.blue,
    LogLevel.warning: Colors.orange,
    LogLevel.error: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Nenhum log ainda.',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          // Show newest first
          final entry = entries[entries.length - 1 - i];
          final color = _levelColors[entry.level] ?? Colors.grey;
          return Text(
            entry.toString(),
            style:
                TextStyle(fontFamily: 'monospace', fontSize: 11, color: color),
          );
        },
      ),
    );
  }
}
