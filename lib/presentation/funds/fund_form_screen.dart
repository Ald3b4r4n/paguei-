import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/funds/providers/funds_provider.dart';

class FundFormScreen extends ConsumerStatefulWidget {
  const FundFormScreen({super.key});

  @override
  ConsumerState<FundFormScreen> createState() => _FundFormScreenState();
}

class _FundFormScreenState extends ConsumerState<FundFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  FundType _selectedType = FundType.savings;
  bool _saving = false;

  static const _typeColors = {
    FundType.emergency: 0xFFE65100,
    FundType.goal: 0xFF1565C0,
    FundType.savings: 0xFF1B4332,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Fundo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do fundo',
                hintText: 'Ex: Reserva de Emergência',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nome obrigatório';
                if (v.length > 100) return 'Máximo 100 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<FundType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: FundType.values
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Meta (R\$)',
                prefixText: 'R\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Meta obrigatória';
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Valor deve ser maior que zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar Fundo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final target = double.parse(_targetController.text.replaceAll(',', '.'));
      await ref.read(fundNotifierProvider.notifier).createFund(
            name: _nameController.text.trim(),
            type: _selectedType,
            targetAmount: Money.fromDouble(target),
            color: _typeColors[_selectedType] ?? 0xFF1B4332,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
