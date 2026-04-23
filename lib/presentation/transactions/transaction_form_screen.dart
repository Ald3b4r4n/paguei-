import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/shared/widgets/category_picker_sheet.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';
import 'package:uuid/uuid.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.existingTransaction});

  final Transaction? existingTransaction;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  Category? _selectedCategory;
  String? _selectedAccountId;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final txn = widget.existingTransaction;
    _amountController = TextEditingController(
      text: txn == null ? '' : txn.amount.amount.toStringAsFixed(2),
    );
    _descriptionController =
        TextEditingController(text: txn?.description ?? '');
    _notesController = TextEditingController(text: txn?.notes ?? '');
    _selectedType = txn?.type ?? TransactionType.expense;
    _selectedDate = txn?.date ?? DateTime.now();
    _selectedAccountId = txn?.accountId;
  }

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
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar transação' : 'Nova transação'),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Erro ao carregar locais do dinheiro: $error'),
        ),
        data: (accounts) => _TransactionFormBody(
          formKey: _formKey,
          amountController: _amountController,
          descriptionController: _descriptionController,
          notesController: _notesController,
          selectedType: _selectedType,
          selectedDate: _selectedDate,
          selectedCategory: _selectedCategory,
          selectedAccountId: _syncSelectedAccount(accounts),
          accounts: accounts,
          isSaving: _isSaving,
          isEditing: _isEditing,
          errorMessage: _errorMessage,
          onTypeChanged: (type) => setState(() => _selectedType = type),
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
          onAccountChanged: (account) {
            setState(() {
              _selectedAccountId = account?.id;
              _errorMessage = null;
            });
          },
          onSave: _save,
        ),
      ),
    );
  }

  String? _syncSelectedAccount(List<Account> accounts) {
    if (accounts.isEmpty) {
      _selectedAccountId = null;
      return null;
    }

    final accountIsAvailable = accounts.any((a) => a.id == _selectedAccountId);
    if (_selectedAccountId != null && !accountIsAvailable) {
      _selectedAccountId = null;
    }

    if (!_isEditing && _selectedAccountId == null && accounts.length == 1) {
      _selectedAccountId = accounts.single.id;
    }

    return _selectedAccountId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );
    if (rawAmount == null || rawAmount <= 0) {
      setState(() => _errorMessage = 'Valor inválido');
      return;
    }

    final accountId = _selectedAccountId;
    if (accountId == null) {
      setState(() => _errorMessage = _accountRequiredMessage(_selectedType));
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final amount = Money.fromDouble(rawAmount);

      if (_isEditing) {
        await ref.read(updateTransactionUseCaseProvider).execute(
              id: widget.existingTransaction!.id,
              description: _descriptionController.text.trim(),
              amount: amount,
              date: _selectedDate,
              type: _selectedType,
              categoryId: _selectedCategory?.id,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      } else {
        await ref.read(createTransactionUseCaseProvider).execute(
              id: const Uuid().v4(),
              accountId: accountId,
              type: _selectedType,
              amount: amount,
              description: _descriptionController.text.trim(),
              date: _selectedDate,
              categoryId: _selectedCategory?.id,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      }

      if (mounted) context.pop();
    } on ValidationException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao salvar transação');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _accountRequiredMessage(TransactionType type) =>
      type == TransactionType.income
          ? 'Escolha para onde entrou'
          : 'Escolha de onde saiu';
}

// ---------------------------------------------------------------------------

class _TransactionFormBody extends StatelessWidget {
  const _TransactionFormBody({
    required this.formKey,
    required this.amountController,
    required this.descriptionController,
    required this.notesController,
    required this.selectedType,
    required this.selectedDate,
    required this.selectedAccountId,
    required this.accounts,
    required this.isSaving,
    required this.isEditing,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.onCategoryChanged,
    required this.onAccountChanged,
    required this.onSave,
    this.selectedCategory,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final TextEditingController notesController;
  final TransactionType selectedType;
  final DateTime selectedDate;
  final Category? selectedCategory;
  final String? selectedAccountId;
  final List<Account> accounts;
  final bool isSaving;
  final bool isEditing;
  final String? errorMessage;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<Category?> onCategoryChanged;
  final ValueChanged<Account?> onAccountChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final canSubmit = !isSaving && accounts.isNotEmpty;
    final saveButton = FilledButton(
      onPressed: canSubmit ? onSave : null,
      child: isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(isEditing ? 'Salvar' : 'Registrar'),
    );

    return Form(
      key: formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                if (errorMessage != null) _ErrorBanner(message: errorMessage!),
                _TypeSelector(
                  selected: selectedType,
                  onChanged: onTypeChanged,
                ),
                const SizedBox(height: 16),
                _AmountField(controller: amountController),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe a descrição';
                    }
                    if (v.length > 255) return 'Máximo de 255 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _DatePicker(
                  date: selectedDate,
                  onChanged: onDateChanged,
                ),
                const SizedBox(height: 16),
                if (accounts.isEmpty)
                  const _NoAccountsEmptyState()
                else
                  _AccountSelector(
                    accounts: accounts,
                    selectedAccountId: selectedAccountId,
                    transactionType: selectedType,
                    onChanged: onAccountChanged,
                  ),
                const SizedBox(height: 16),
                _CategorySelector(
                  selected: selectedCategory,
                  type: selectedType,
                  onChanged: onCategoryChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: saveButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Despesa'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Receita'),
          icon: Icon(Icons.arrow_downward),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class _AccountSelector extends StatelessWidget {
  const _AccountSelector({
    required this.accounts,
    required this.selectedAccountId,
    required this.transactionType,
    required this.onChanged,
  });

  final List<Account> accounts;
  final String? selectedAccountId;
  final TransactionType transactionType;
  final ValueChanged<Account?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedAccount = accounts
        .where((account) => account.id == selectedAccountId)
        .firstOrNull;
    final accountIds = accounts.map((account) => account.id).join('|');

    final label = transactionType == TransactionType.income
        ? 'Para onde entrou?'
        : 'De onde saiu?';
    final validationMessage = transactionType == TransactionType.income
        ? 'Escolha para onde entrou'
        : 'Escolha de onde saiu';

    return DropdownButtonFormField<Account>(
      key: ValueKey(
        'account-${selectedAccount?.id ?? 'none'}-$accountIds',
      ),
      initialValue: selectedAccount,
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Ex.: Carteira, Nubank, Caixa, Inter ou dinheiro vivo',
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      hint: const Text('Escolha um local'),
      items: accounts
          .map(
            (account) => DropdownMenuItem<Account>(
              value: account,
              child: Text(account.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? validationMessage : null,
    );
  }
}

class _NoAccountsEmptyState extends StatelessWidget {
  const _NoAccountsEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nenhum local do dinheiro cadastrado',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione Carteira, Nubank, Caixa ou dinheiro vivo para continuar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/contas/nova'),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar local'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.type,
    required this.onChanged,
  });

  final Category? selected;
  final TransactionType type;
  final ValueChanged<Category?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final cat = await CategoryPickerSheet.show(
          context,
          selectedId: selected?.id,
          filter: type == TransactionType.expense
              ? null // allow both for flexibility
              : null,
        );
        if (cat != null) onChanged(cat);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Categoria (opcional)',
          border: const OutlineInputBorder(),
          suffixIcon: selected != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.chevron_right),
        ),
        child: Text(selected?.name ?? 'Selecionar categoria'),
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
