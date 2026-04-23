import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/accounts/widgets/account_card.dart';
import 'package:paguei/presentation/shared/widgets/money_text.dart';
import 'package:paguei/domain/value_objects/money.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locais do dinheiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar local',
            onPressed: () => context.push('/contas/nova'),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(error: error),
        data: (accounts) => accounts.isEmpty
            ? const _EmptyState()
            : _AccountList(accounts: accounts),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AccountList extends ConsumerWidget {
  const _AccountList({required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = accounts.fold(
      Money.zero,
      (sum, a) => sum + a.currentBalance,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TotalBalanceHeader(total: totalBalance),
        ),
        SliverList.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AccountCard(
                account: account,
                onTap: () => context.push(
                  '/contas/${account.id}/editar',
                  extra: account,
                ),
                onLongPress: () => _showAccountActions(context, ref, account),
              ),
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  void _showAccountActions(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _AccountActionsSheet(account: account, ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------

class _TotalBalanceHeader extends StatelessWidget {
  const _TotalBalanceHeader({required this.total});

  final Money total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo disponível',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          MoneyText(
            total,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AccountActionsSheet extends StatelessWidget {
  const _AccountActionsSheet({required this.account, required this.ref});

  final Account account;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar local'),
            onTap: () {
              Navigator.pop(context);
              context.push('/contas/${account.id}/editar', extra: account);
            },
          ),
          ListTile(
            leading: Icon(
              account.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            title:
                Text(account.isArchived ? 'Restaurar local' : 'Arquivar local'),
            onTap: () async {
              Navigator.pop(context);
              final notifier = ref.read(accountNotifierProvider.notifier);
              if (account.isArchived) {
                await notifier.unarchive(account.id);
              } else {
                await notifier.archive(account.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum local cadastrado',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione Carteira, Nubank, Caixa ou dinheiro vivo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => GoRouter.of(context).push('/contas/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar local'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text('Erro ao carregar locais',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
