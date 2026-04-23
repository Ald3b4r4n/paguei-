import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:uuid/uuid.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.existingAccount});

  /// Null when creating a new account; non-null when editing.
  final Account? existingAccount;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _selectedType;
  bool _isSaving = false;

  bool get _isEditing => widget.existingAccount != null;

  @override
  void initState() {
    super.initState();
    final account = widget.existingAccount;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account == null
          ? ''
          : account.currentBalance.amount.toStringAsFixed(2),
    );
    _selectedType = account?.type ?? AccountType.checking;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar local' : 'Novo local'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Onde está seu dinheiro? *',
                hintText: 'Ex.: Carteira, Nubank, Caixa, dinheiro vivo',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe onde está seu dinheiro.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account type picker
            _AccountTypePicker(
              selected: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 16),

            // Initial / current balance
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Saldo atual (R\$)',
                hintText: '0,00',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) return 'Valor inválido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Salvar alterações' : 'Adicionar local'),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSaving ? null : _confirmArchive,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(
                  widget.existingAccount!.isArchived
                      ? 'Restaurar local'
                      : 'Arquivar local',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final balanceText = _balanceController.text.trim().replaceAll(',', '.');
      final balanceDouble =
          balanceText.isEmpty ? 0.0 : double.parse(balanceText);
      final balance = Money.fromDouble(balanceDouble);

      final notifier = ref.read(accountNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.updateAccount(
          id: widget.existingAccount!.id,
          name: _nameController.text.trim(),
          type: _selectedType,
          currentBalance: balance,
        );
      } else {
        await notifier.createAccount(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          type: _selectedType,
          initialBalance: balance,
        );
      }

      if (mounted) context.pop();
    } on ValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmArchive() async {
    final account = widget.existingAccount!;
    final isArchiving = !account.isArchived;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArchiving ? 'Arquivar local' : 'Restaurar local'),
        content: Text(
          isArchiving
              ? 'O local "${account.name}" será arquivado e não aparecerá nas listagens. Deseja continuar?'
              : 'O local "${account.name}" será restaurado. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArchiving ? 'Arquivar' : 'Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notifier = ref.read(accountNotifierProvider.notifier);
    if (isArchiving) {
      await notifier.archive(account.id);
    } else {
      await notifier.unarchive(account.id);
    }

    if (mounted) context.pop();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }
}

// ---------------------------------------------------------------------------

class _AccountTypePicker extends StatelessWidget {
  const _AccountTypePicker({
    required this.selected,
    required this.onChanged,
  });

  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de local', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AccountType.values.map((type) {
            final isSelected = type == selected;
            return ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}
