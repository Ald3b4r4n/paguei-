import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';
import 'package:uuid/uuid.dart';

class TransferFormScreen extends ConsumerStatefulWidget {
  const TransferFormScreen({super.key});

  @override
  ConsumerState<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController(text: 'Transferência');
  final _notesController = TextEditingController();

  Account? _fromAccount;
  Account? _toAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transferir dinheiro')),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (accounts) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
              _AccountDropdown(
                label: 'Origem',
                validationMessage: 'Escolha a origem',
                accounts: accounts,
                selected: _fromAccount,
                excluded: _toAccount,
                onChanged: (a) => setState(() => _fromAccount = a),
              ),
              const SizedBox(height: 8),
              Center(
                child: IconButton(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'Inverter origem e destino',
                  onPressed: () {
                    setState(() {
                      final temp = _fromAccount;
                      _fromAccount = _toAccount;
                      _toAccount = temp;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              _AccountDropdown(
                label: 'Destino',
                validationMessage: 'Escolha o destino',
                accounts: accounts,
                selected: _toAccount,
                excluded: _fromAccount,
                onChanged: (a) => setState(() => _toAccount = a),
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
                  if (d == null || d <= 0) {
                    return 'Valor deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 16),
              _DatePicker(
                date: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
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
                icon: const Icon(Icons.swap_horiz),
                label: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Transferir'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAccount == null || _toAccount == null) {
      setState(() => _errorMessage = 'Escolha origem e destino');
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      setState(
          () => _errorMessage = 'Origem e destino precisam ser diferentes');
      return;
    }

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
      await ref.read(transactionNotifierProvider.notifier).transfer(
            id: const Uuid().v4(),
            fromAccountId: _fromAccount!.id,
            toAccountId: _toAccount!.id,
            amount: Money.fromDouble(rawAmount),
            description: _descriptionController.text.trim(),
            date: _selectedDate,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) context.pop();
    } on ValidationException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao realizar transferência');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ---------------------------------------------------------------------------

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.validationMessage,
    required this.accounts,
    required this.selected,
    required this.excluded,
    required this.onChanged,
  });

  final String label;
  final String validationMessage;
  final List<Account> accounts;
  final Account? selected;
  final Account? excluded;
  final ValueChanged<Account?> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = accounts.where((a) => a.id != excluded?.id).toList();

    return DropdownButtonFormField<Account>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Escolha Carteira, banco ou dinheiro vivo',
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      hint: const Text('Escolha um local'),
      items: available
          .map(
            (a) => DropdownMenuItem(
              value: a,
              child: Text(a.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? validationMessage : null,
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.date, required this.onChanged});

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
          labelText: 'Data',
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
