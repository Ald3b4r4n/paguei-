import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/scan_source_type.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/categories/providers/categories_provider.dart';
import 'package:paguei/presentation/shared/widgets/category_picker_sheet.dart';
import 'package:uuid/uuid.dart';

/// Review screen shown after a successful scan/OCR.
///
/// Displays pre-filled fields from [ParsedBillData] and lets the user confirm
/// or correct them before saving. When [ParsedBillData.isHighConfidence] is
/// false a prominent warning banner is shown requesting manual review.
class BillReviewScreen extends ConsumerStatefulWidget {
  const BillReviewScreen({super.key, required this.parsedData});

  /// The structured data extracted from the scan. Passed as route `extra`.
  final ParsedBillData parsedData;

  @override
  ConsumerState<BillReviewScreen> createState() => _BillReviewScreenState();
}

class _BillReviewScreenState extends ConsumerState<BillReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _notesController;

  late DateTime _dueDate;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _isSaving = false;
  String? _errorMessage;

  ParsedBillData get _data => widget.parsedData;

  @override
  void initState() {
    super.initState();
    // Pre-fill from parsed data. Title defaults to beneficiary if present.
    _titleController = TextEditingController(text: _data.beneficiary ?? '');
    _amountController = TextEditingController(
      text: _data.amount != null
          ? _data.amount!.amount.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _barcodeController = TextEditingController(
      text: _data.barcode ?? _data.pixCode ?? '',
    );
    _notesController = TextEditingController();
    _dueDate = _data.dueDate ?? DateTime.now().add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar boleto'),
        actions: [
          _ConfidenceBadge(confidence: _data.confidence),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Review-required banner ──────────────────────────────────────
            if (!_data.isHighConfidence) ...[
              _ReviewRequiredBanner(source: _data.source.name),
              const SizedBox(height: 16),
            ],

            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 0),
            ],

            // ── Extraction proof ────────────────────────────────────────────
            _SourceChips(data: _data),
            const SizedBox(height: 10),
            _FieldConfidencePanel(data: _data),
            if (_data.hasPixCode && _hasPixMetadata(_data)) ...[
              const SizedBox(height: 12),
              _PixMetadataPanel(data: _data),
            ],
            if (_data.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ConflictBanner(warnings: _data.warnings),
            ],
            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título / Beneficiário',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: 16),

            // ── Amount ──────────────────────────────────────────────────────
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                border: const OutlineInputBorder(),
                suffixIcon: _data.hasAmount
                    ? const Tooltip(
                        message: 'Valor extraído automaticamente',
                        child: Icon(Icons.auto_fix_high, size: 18),
                      )
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o valor';
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null || d <= 0) return 'Valor deve ser maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Due date ────────────────────────────────────────────────────
            _DueDatePicker(
              date: _dueDate,
              wasExtracted: _data.hasDueDate,
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 16),

            // ── Account ─────────────────────────────────────────────────────
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (accounts) => DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'De onde vai sair? (opcional)',
                  helperText: 'Escolha Carteira, banco ou dinheiro vivo',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                hint: const Text('Escolha um local'),
                items: accounts
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category ────────────────────────────────────────────────────
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) => InkWell(
                onTap: () async {
                  final picked = await CategoryPickerSheet.show(
                    context,
                    selectedId: _selectedCategoryId,
                  );
                  if (picked != null) {
                    setState(() => _selectedCategoryId = picked.id);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Categoria (opcional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.chevron_right),
                  ),
                  child: Text(
                    _selectedCategoryId != null
                        ? categories
                                .where((c) => c.id == _selectedCategoryId)
                                .firstOrNull
                                ?.name ??
                            'Selecionar'
                        : 'Selecionar',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Barcode / PIX ────────────────────────────────────────────────
            TextFormField(
              controller: _barcodeController,
              keyboardType:
                  _data.hasPixCode ? TextInputType.text : TextInputType.number,
              decoration: InputDecoration(
                labelText: _data.hasPixCode
                    ? 'Código PIX (opcional)'
                    : 'Código de barras (opcional)',
                border: const OutlineInputBorder(),
                suffixIcon: (_data.hasBarcode || _data.hasPixCode)
                    ? const Tooltip(
                        message: 'Código extraído automaticamente',
                        child: Icon(Icons.qr_code, size: 18),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── Notes ───────────────────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar Boleto'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isSaving ? null : () => context.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPixMetadata(ParsedBillData data) =>
      data.pixKey != null ||
      data.pixLocationUrl != null ||
      data.pixMerchantName != null ||
      data.pixCity != null ||
      data.pixTxId != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (rawAmount == null || rawAmount <= 0) {
      setState(() => _errorMessage = 'Valor inválido');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Try to parse barcode/PIX — silently ignore if invalid, they become
      // optional fields. This keeps saving non-blocking for partial scans.
      Barcode? barcode;
      PixCode? pixCode;
      final codeRaw = _barcodeController.text.trim();
      if (codeRaw.isNotEmpty) {
        if (_data.hasPixCode) {
          try {
            pixCode = PixCode(codeRaw);
          } on ValidationException {
            // ignore — store raw in notes instead
          }
        } else {
          try {
            barcode = Barcode(codeRaw);
          } on ValidationException {
            // ignore — barcode might be partially extracted
          }
        }
      }

      await ref.read(createBillUseCaseProvider).execute(
            id: const Uuid().v4(),
            title: _titleController.text.trim(),
            amount: Money.fromDouble(rawAmount),
            dueDate: _dueDate,
            accountId: _selectedAccountId,
            categoryId: _selectedCategoryId,
            barcode: barcode,
            pixCode: pixCode,
            beneficiary: _data.beneficiary,
            issuer: _data.issuer,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        // Navigate back to boletos list root, clearing the scanner stack.
        context.go('/boletos');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao salvar boleto: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _SourceChips extends StatelessWidget {
  const _SourceChips({required this.data});

  final ParsedBillData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <_SourceChipData>[
      if (data.hasPixCode)
        const _SourceChipData('[PIX]', Icons.qr_code_2_outlined),
      if (data.hasBarcode)
        const _SourceChipData('Barcode', Icons.document_scanner_outlined),
      if (data.source == ScanSourceType.pdf)
        const _SourceChipData('PDF Text', Icons.picture_as_pdf_outlined),
      if (data.source == ScanSourceType.image)
        const _SourceChipData('OCR fallback', Icons.image_search_outlined),
    ];

    if (chips.isEmpty) {
      chips.add(_SourceChipData(data.source.label, Icons.edit_outlined));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          Chip(
            avatar: Icon(
              chip.icon,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            label: Text(
              chip.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: theme.colorScheme.secondaryContainer,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _FieldConfidencePanel extends StatelessWidget {
  const _FieldConfidencePanel({required this.data});

  final ParsedBillData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verifiedSource = data.hasBarcode
        ? 'Código validado'
        : data.source == ScanSourceType.pdf
            ? 'PDF Text'
            : data.source == ScanSourceType.image
                ? 'OCR fallback'
                : data.source.label;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _FieldConfidenceRow(
            label: 'Valor',
            isVerified: data.hasAmount,
            source: verifiedSource,
          ),
          const SizedBox(height: 8),
          _FieldConfidenceRow(
            label: 'Vencimento',
            isVerified: data.hasDueDate,
            source: verifiedSource,
          ),
          const SizedBox(height: 8),
          _FieldConfidenceRow(
            label: 'Beneficiário',
            isVerified: data.beneficiary != null,
            source: data.beneficiary != null ? 'Entidade reconhecida' : null,
          ),
          if (data.issuer != null) ...[
            const SizedBox(height: 8),
            _FieldConfidenceRow(
              label: 'Banco',
              isVerified: true,
              source: data.issuer,
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldConfidenceRow extends StatelessWidget {
  const _FieldConfidenceRow({
    required this.label,
    required this.isVerified,
    this.source,
  });

  final String label;
  final bool isVerified;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isVerified ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle : Icons.help_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ${isVerified ? '✓' : '?'}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (source != null)
          Flexible(
            child: Text(
              source!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _PixMetadataPanel extends StatelessWidget {
  const _PixMetadataPanel({required this.data});

  final ParsedBillData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <({String label, String value})>[
      if (data.pixMerchantName != null)
        (label: 'Recebedor', value: data.pixMerchantName!),
      if (data.pixKey != null)
        (label: 'Chave/identificador', value: data.pixKey!),
      if (data.pixCity != null) (label: 'Cidade', value: data.pixCity!),
      if (data.pixTxId != null) (label: 'TXID', value: data.pixTxId!),
      if (data.pixLocationUrl != null)
        (label: 'Payload dinâmico', value: data.pixLocationUrl!),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados PIX',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows) ...[
            _PixMetadataRow(label: row.label, value: row.value),
            if (row != rows.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _PixMetadataRow extends StatelessWidget {
  const _PixMetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.rule_folder_outlined,
            size: 20,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirme os dados',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                for (final warning in warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      warning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _SourceChipData {
  const _SourceChipData(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Orange banner shown when confidence is below the high-confidence threshold.
class _ReviewRequiredBanner extends StatelessWidget {
  const _ReviewRequiredBanner({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.tertiary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revisão necessária',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A extração automática pode ter erros. '
                  'Confira os dados antes de salvar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small badge showing confidence percentage in the app bar.
class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.85
        ? Colors.green
        : confidence >= 0.55
            ? Colors.orange
            : Colors.red;

    return Tooltip(
      message: 'Confiança da extração: $pct%',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          '$pct%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  const _DueDatePicker({
    required this.date,
    required this.onChanged,
    this.wasExtracted = false,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final bool wasExtracted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('pt', 'BR'),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Vencimento',
          border: const OutlineInputBorder(),
          suffixIcon: wasExtracted
              ? const Tooltip(
                  message: 'Data extraída automaticamente',
                  child: Icon(Icons.auto_fix_high, size: 18),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}',
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
