import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/categories/providers/categories_provider.dart';
import 'package:paguei/presentation/shared/widgets/category_picker_sheet.dart';
import 'package:uuid/uuid.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key});

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _isSaving = false;
  String? _errorMessage;

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
      appBar: AppBar(title: const Text('Novo boleto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o valor';
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null || d <= 0) return 'Valor deve ser maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _DueDatePicker(
              date: _dueDate,
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 16),
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
                    .map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
            ),
            const SizedBox(height: 16),
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
            TextFormField(
              controller: _barcodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de barras (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

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
      await ref.read(createBillUseCaseProvider).execute(
            id: const Uuid().v4(),
            title: _titleController.text.trim(),
            amount: Money.fromDouble(rawAmount),
            dueDate: _dueDate,
            accountId: _selectedAccountId,
            categoryId: _selectedCategoryId,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao salvar boleto');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DueDatePicker extends StatelessWidget {
  const _DueDatePicker({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

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
        decoration: const InputDecoration(
          labelText: 'Vencimento',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
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
