import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:paguei/presentation/settings/providers/export_provider.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// Central hub for exporting financial data to CSV.
///
/// Provides one-tap exports for:
/// - All transactions (with optional date range)
/// - Monthly category-aggregated report (month picker)
/// - Bills report
/// - Debts snapshot
///
/// All files are written to a temp directory and shared via the OS share sheet
/// ([SharePlus]).
class ExportCenterScreen extends ConsumerStatefulWidget {
  const ExportCenterScreen({super.key});

  @override
  ConsumerState<ExportCenterScreen> createState() => _ExportCenterScreenState();
}

class _ExportCenterScreenState extends ConsumerState<ExportCenterScreen> {
  // Selected month for monthly report (defaults to current month)
  late int _reportYear;
  late int _reportMonth;

  // Date range for transactions export (null = all time)
  DateTimeRange? _transactionsRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _reportYear = now.year;
    _reportMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final exportState = ref.watch(csvExportProvider);

    // Auto-share on success and clean up temp file
    ref.listen(csvExportProvider, (_, next) {
      if (next is CsvExportSuccess) {
        _shareFile(next.file);
      } else if (next is CsvExportError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(csvExportProvider.notifier).clearStatus();
      }
    });

    final isLoading = exportState is CsvExportInProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Exportação'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.screenPaddingV,
        ),
        children: [
          // Description
          Text(
            'Exporte seus dados financeiros em formato CSV para abrir no '
            'Excel, Google Sheets ou qualquer planilha.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Transactions export ─────────────────────────────────────────
          _ExportCard(
            icon: Icons.receipt_long_outlined,
            color: cs.primary,
            title: 'Transações',
            description: _transactionsRange == null
                ? 'Todas as transações'
                : '${_formatDate(_transactionsRange!.start)} → '
                    '${_formatDate(_transactionsRange!.end)}',
            trailing: TextButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.date_range, size: 16),
              label: const Text('Período'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                visualDensity: VisualDensity.compact,
              ),
            ),
            isLoading: isLoading,
            onExport: () => ref
                .read(csvExportProvider.notifier)
                .exportTransactions(dateRange: _transactionsRange),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Monthly report ──────────────────────────────────────────────
          _ExportCard(
            icon: Icons.bar_chart_outlined,
            color: cs.tertiary,
            title: 'Relatório Mensal',
            description: '${_monthName(_reportMonth)} $_reportYear',
            trailing: TextButton.icon(
              onPressed: () => _pickMonth(context),
              icon: const Icon(Icons.calendar_month, size: 16),
              label: const Text('Mês'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                visualDensity: VisualDensity.compact,
              ),
            ),
            isLoading: isLoading,
            onExport: () => ref
                .read(csvExportProvider.notifier)
                .exportMonthlyReport(year: _reportYear, month: _reportMonth),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Bills report ────────────────────────────────────────────────
          _ExportCard(
            icon: Icons.description_outlined,
            color: Colors.orange,
            title: 'Boletos',
            description: 'Todos os boletos e status de pagamento.',
            isLoading: isLoading,
            onExport: () => ref.read(csvExportProvider.notifier).exportBills(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Debts snapshot ──────────────────────────────────────────────
          _ExportCard(
            icon: Icons.account_balance_outlined,
            color: cs.error,
            title: 'Dívidas',
            description: 'Snapshot atual de todas as dívidas.',
            isLoading: isLoading,
            onExport: () => ref.read(csvExportProvider.notifier).exportDebts(),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _transactionsRange,
      helpText: 'Selecione o período',
    );
    if (range != null) {
      setState(() => _transactionsRange = range);
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await _showMonthYearPicker(context);
    if (picked != null) {
      setState(() {
        _reportYear = picked.year;
        _reportMonth = picked.month;
      });
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Paguei — ${file.path.split('/').last}',
        ),
      );
    } finally {
      // Delete temp file after sharing attempt
      try {
        await file.delete();
      } catch (_) {}
      if (mounted) {
        ref.read(csvExportProvider.notifier).clearStatus();
      }
    }
  }

  // ── Month/year picker dialog ──────────────────────────────────────────────

  Future<DateTime?> _showMonthYearPicker(BuildContext context) async {
    final now = DateTime.now();
    int year = _reportYear;
    int month = _reportMonth;

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Selecionar Mês'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => year--),
                  ),
                  Text('$year', style: Theme.of(ctx).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        year < now.year ? () => setState(() => year++) : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final isSelected = m == month;
                  final isFuture = year == now.year && m > now.month;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    onTap: isFuture ? null : () => setState(() => month = m),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        _shortMonthName(m),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.onPrimary
                              : isFuture
                                  ? Theme.of(ctx).colorScheme.outline
                                  : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, DateTime(year, month)),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  static String _monthName(int m) => const [
        'Janeiro',
        'Fevereiro',
        'Março',
        'Abril',
        'Maio',
        'Junho',
        'Julho',
        'Agosto',
        'Setembro',
        'Outubro',
        'Novembro',
        'Dezembro',
      ][m - 1];

  static String _shortMonthName(int m) => const [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez',
      ][m - 1];
}

// ---------------------------------------------------------------------------
// _ExportCard
// ---------------------------------------------------------------------------

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onExport,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onExport;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(description,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onExport,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text(isLoading ? 'Exportando…' : 'Exportar CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
