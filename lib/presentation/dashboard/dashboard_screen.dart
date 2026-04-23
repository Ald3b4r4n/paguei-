import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/presentation/dashboard/providers/dashboard_provider.dart';
import 'package:paguei/presentation/dashboard/widgets/balance_card.dart';
import 'package:paguei/presentation/dashboard/widgets/bills_summary_card.dart';
import 'package:paguei/presentation/dashboard/widgets/upcoming_bills_section.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            _DashboardAppBar(),
            switch (state) {
              DashboardLoading() => const SliverFillRemaining(
                  child: _LoadingBody(),
                ),
              DashboardError(:final message) => SliverFillRemaining(
                  child: _ErrorBody(message: message),
                ),
              DashboardLoaded(:final summary) => _LoadedBody(summary: summary),
            },
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const _QuickActionsRow(),
    );
  }
}

// ---------------------------------------------------------------------------
// Parallax app bar — T125
// ---------------------------------------------------------------------------

class _DashboardAppBar extends StatelessWidget {
  static const _expandedHeight = 130.0;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? AppGradients.primaryVerticalDark
        : AppGradients.primaryVertical;

    return SliverAppBar(
      expandedHeight: _expandedHeight,
      floating: false,
      pinned: true,
      snap: false,
      // Match gradient so collapsed bar stays on-brand
      backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
          tooltip: 'Notificações',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // Disable Flutter's default title centering — we handle layout
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12, right: 56),
        title: Text(
          greeting,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        // Gradient parallax background
        background: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aqui está seu resumo financeiro',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Parallax scroll effect
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body — staggered entrance animations
// ---------------------------------------------------------------------------

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Cards animate in with staggered delays (T125 microinteractions)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BalanceCard(summary: summary),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BillsSummaryCard(summary: summary),
        )
            .animate()
            .fadeIn(delay: 80.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0),
        if (summary.hasOverdueBills)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _OverdueWarningBanner(count: summary.overdueBillsCount),
          )
              .animate()
              .fadeIn(delay: 140.ms, duration: 350.ms)
              .slideY(begin: 0.06, end: 0),
        const SizedBox(height: 8),
        UpcomingBillsSection(bills: summary.upcomingBills)
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0),
        const SizedBox(height: 100),
      ]),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        BalanceCardLoading(),
        SizedBox(height: 12),
        BillsSummaryCardLoading(),
        SizedBox(height: 12),
        UpcomingBillsSectionLoading(),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dashboard',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OverdueWarningBanner extends StatelessWidget {
  const _OverdueWarningBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'boleto vencido' : 'boletos vencidos'}! Regularize sua situação.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12, right: 4),
      child: FloatingActionButton.extended(
        heroTag: 'dashboard_add',
        onPressed: () => _showActions(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Nova transação'),
              subtitle: const Text('Receita ou despesa'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.transactionNew);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Novo boleto'),
              subtitle: const Text('Escanear, importar ou preencher'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.bills);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Transferir'),
              subtitle: const Text('Entre dois locais do dinheiro'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.transactionTransfer);
              },
            ),
          ],
        ),
      ),
    );
  }
}
