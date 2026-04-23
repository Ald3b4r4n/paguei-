import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:paguei/application/export/backup_service.dart';
import 'package:paguei/application/export/restore_service.dart';
import 'package:paguei/presentation/settings/providers/backup_provider.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// Screen for managing encrypted backups.
///
/// Features:
/// - Last backup timestamp
/// - One-tap backup button (optional password)
/// - Import / restore from file
/// - Restore mode selection (merge vs replace)
class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  bool _usePassword = false;
  RestoreMode _restoreMode = RestoreMode.merge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final operationState = ref.watch(backupSettingsProvider);
    final lastBackupAsync = ref.watch(lastBackupProvider);

    // Show snackbar on state change
    ref.listen(backupSettingsProvider, (_, next) {
      if (next is BackupSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is BackupError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isLoading = operationState is BackupInProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e Restauração'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.screenPaddingV,
        ),
        children: [
          // ── Last backup card ──────────────────────────────────────────
          _LastBackupCard(lastBackupAsync: lastBackupAsync),
          const SizedBox(height: AppSpacing.xxl),

          // ── Create backup section ─────────────────────────────────────
          _SectionHeader(
            icon: Icons.backup_outlined,
            title: 'Criar Backup',
            color: cs.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exporte todos os seus dados em um arquivo criptografado '
                    'que pode ser importado em qualquer dispositivo.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _usePassword,
                    onChanged: (v) => setState(() => _usePassword = v),
                    title: const Text('Proteger com senha'),
                    subtitle: const Text(
                        'Criptografa o backup com uma senha pessoal.'),
                    secondary: Icon(
                      _usePassword ? Icons.lock : Icons.lock_open_outlined,
                      color: _usePassword ? cs.primary : cs.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : _onCreateBackup,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(
                        isLoading ? 'Criando…' : 'Criar Backup Agora',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Restore section ───────────────────────────────────────────
          _SectionHeader(
            icon: Icons.restore_outlined,
            title: 'Restaurar Backup',
            color: cs.tertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione um arquivo .paguei.backup para restaurar '
                    'seus dados.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Restore mode selector
                  Text('Modo de restauração',
                      style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<RestoreMode>(
                    segments: const [
                      ButtonSegment(
                        value: RestoreMode.merge,
                        label: Text('Mesclar'),
                        icon: Icon(Icons.merge_outlined),
                      ),
                      ButtonSegment(
                        value: RestoreMode.replace,
                        label: Text('Substituir'),
                        icon: Icon(Icons.sync_outlined),
                      ),
                    ],
                    selected: {_restoreMode},
                    onSelectionChanged: (s) =>
                        setState(() => _restoreMode = s.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RestoreModeHint(mode: _restoreMode),
                  const SizedBox(height: AppSpacing.lg),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _onRestoreBackup,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Selecionar Arquivo…'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onCreateBackup() async {
    String? password;
    if (_usePassword) {
      password = await _showPasswordDialog(context, confirmMode: true);
      if (password == null) return; // user cancelled
    }

    final notifier = ref.read(backupSettingsProvider.notifier);
    final file = await notifier.createBackup(
      appVersion: '1.0.0', // TODO: read from package_info_plus
      password: password,
    );

    if (file != null && mounted) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/octet-stream')],
          subject: 'Paguei — Backup',
        ),
      );
    }
  }

  Future<void> _onRestoreBackup() async {
    // Pick file
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);

    // Preview first
    final notifier = ref.read(backupSettingsProvider.notifier);
    final preview = await notifier.previewBackup(file);
    if (preview == null || !mounted) return;

    // Show preview dialog and get confirmation + optional password
    final confirmed = await _showRestorePreviewDialog(context, preview);
    if (confirmed == null || !mounted) return;

    // If encrypted, ask for password
    String? password;
    if (preview.isEncrypted) {
      password = await _showPasswordDialog(context, confirmMode: false);
      if (password == null) return;
    }

    await notifier.restoreBackup(
      file: file,
      password: password,
      mode: _restoreMode,
    );

    // Clean up temp file if picked from a cache dir
    try {
      if (file.path.contains('cache')) await file.delete();
    } catch (_) {}
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  /// Shows a password input dialog. [confirmMode] = true shows a confirm field.
  /// Returns null if cancelled, otherwise the entered password.
  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required bool confirmMode,
  }) async {
    final pwController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(confirmMode ? 'Definir Senha do Backup' : 'Senha do Backup'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe uma senha.' : null,
              ),
              if (confirmMode) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v != pwController.text
                      ? 'As senhas não coincidem.'
                      : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, pwController.text);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// Shows a preview dialog with entity counts and version info.
  /// Returns `true` if the user confirms the restore, `null` if cancelled.
  Future<bool?> _showRestorePreviewDialog(
    BuildContext context,
    RestorePreview preview,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Prévia do Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!preview.isVersionSupported)
                _WarningChip(
                  label:
                      'Versão do backup (v${preview.backupVersion}) não suportada.',
                  color: cs.error,
                ),
              _PreviewRow(
                  label: 'Exportado em',
                  value: _formatDate(preview.exportedAt)),
              _PreviewRow(label: 'Versão', value: 'v${preview.backupVersion}'),
              const Divider(height: AppSpacing.xl),
              _PreviewRow(
                  label: 'Locais do dinheiro',
                  value: '${preview.accountCount}'),
              _PreviewRow(
                  label: 'Transações', value: '${preview.transactionCount}'),
              _PreviewRow(label: 'Boletos', value: '${preview.billCount}'),
              _PreviewRow(label: 'Dívidas', value: '${preview.debtCount}'),
              _PreviewRow(label: 'Fundos', value: '${preview.fundCount}'),
              _PreviewRow(
                  label: 'Categorias', value: '${preview.categoryCount}'),
              if (preview.isEncrypted)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 16, color: cs.primary),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Backup criptografado'),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            if (preview.isVersionSupported)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restaurar'),
              ),
          ],
        );
      },
    );
  }

  static String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.year}  '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _LastBackupCard extends StatelessWidget {
  const _LastBackupCard({required this.lastBackupAsync});

  final AsyncValue<DateTime?> lastBackupAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary,
              child: Icon(Icons.history, color: cs.onPrimary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Último Backup',
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onPrimaryContainer)),
                  lastBackupAsync.when(
                    data: (date) => Text(
                      date == null
                          ? 'Nenhum backup realizado'
                          : _formatDate(date),
                      style: tt.bodyLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                    loading: () => const Text('Carregando…'),
                    error: (_, __) => const Text('Erro ao carregar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.year}  '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RestoreModeHint extends StatelessWidget {
  const _RestoreModeHint({required this.mode});

  final RestoreMode mode;

  @override
  Widget build(BuildContext context) {
    final text = switch (mode) {
      RestoreMode.merge =>
        'Registros existentes são mantidos. Apenas novos dados '
            'do backup são inseridos.',
      RestoreMode.replace =>
        'Registros existentes são substituídos pelos dados '
            'do backup. Novos dados também são inseridos.',
    };
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
