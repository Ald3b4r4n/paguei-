import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/debts/providers/debts_provider.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';

/// Form screen for registering a new debt.
class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key});

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _creditorController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _expectedEndDate;
  bool _hasInstallments = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _creditorController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    _installmentAmountController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Dívida'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),

            // Creditor name
            TextFormField(
              controller: _creditorController,
              decoration: const InputDecoration(
                labelText: 'Credor / Instituição *',
                hintText: 'Ex: Banco, loja, pessoa...',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o nome do credor.';
                }
                if (v.trim().length > 150) {
                  return 'Máximo 150 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Total amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Valor total da dívida *',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final parsed = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Informe um valor maior que zero.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Installments toggle
            SwitchListTile(
              value: _hasInstallments,
              onChanged: (v) => setState(() => _hasInstallments = v),
              title: const Text('Parcelado'),
              subtitle: const Text('Dívida dividida em parcelas'),
              contentPadding: EdgeInsets.zero,
            ),

            if (_hasInstallments) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _installmentsController,
                      decoration: const InputDecoration(
                        labelText: 'Nº de parcelas',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _installmentAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Valor da parcela',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Interest rate (optional)
            TextFormField(
              controller: _interestRateController,
              decoration: const InputDecoration(
                labelText: 'Taxa de juros (% a.m.)',
                hintText: 'Opcional',
                suffixText: '%',
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),

            // Expected end date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _expectedEndDate == null
                    ? 'Data prevista de quitação (opcional)'
                    : 'Quitação: ${_formatDate(_expectedEndDate!)}',
              ),
              trailing: _expectedEndDate != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _expectedEndDate = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                );
                if (picked != null) {
                  setState(() => _expectedEndDate = picked);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Opcional',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar Dívida'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final totalAmount = Money.fromDouble(
        double.parse(_amountController.text.replaceAll(',', '.')),
      );

      int? installments;
      Money? installmentAmount;
      if (_hasInstallments) {
        final numStr = _installmentsController.text.trim();
        if (numStr.isNotEmpty) {
          installments = int.tryParse(numStr);
        }
        final amtStr =
            _installmentAmountController.text.replaceAll(',', '.').trim();
        if (amtStr.isNotEmpty) {
          final amt = double.tryParse(amtStr);
          if (amt != null && amt > 0) {
            installmentAmount = Money.fromDouble(amt);
          }
        }
      }

      double? interestRate;
      final rateStr = _interestRateController.text.replaceAll(',', '.').trim();
      if (rateStr.isNotEmpty) {
        interestRate = double.tryParse(rateStr);
      }

      await ref.read(debtNotifierProvider.notifier).createDebt(
            creditorName: _creditorController.text.trim(),
            totalAmount: totalAmount,
            installments: installments,
            installmentAmount: installmentAmount,
            interestRate: interestRate,
            expectedEndDate: _expectedEndDate?.toUtc(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) Navigator.of(context).pop();
    } on ValidationException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
