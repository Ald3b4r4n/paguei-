import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/core/utils/currency_formatter.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/notification_preferences.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/dashboard/providers/dashboard_provider.dart';
import 'package:paguei/presentation/debts/providers/debts_provider.dart';
import 'package:paguei/presentation/funds/providers/funds_provider.dart';
import 'package:paguei/presentation/notifications/providers/notifications_provider.dart';
import 'package:paguei/presentation/theme/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings screen that lets users control all notification preferences.
///
/// Changes are persisted immediately via [NotificationPreferencesNotifier] and
/// all pending notifications are rescheduled accordingly.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (prefs) => _SettingsBody(prefs: prefs),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.prefs});

  final NotificationPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return ListView(
      children: [
        // ── Reminder types ────────────────────────────────────────────────
        _SectionHeader(title: 'Tipos de Lembretes'),
        _PrefSwitch(
          icon: Icons.receipt_long_outlined,
          title: 'Boletos',
          subtitle: 'Avise-me sobre boletos próximos ao vencimento.',
          value: prefs.billRemindersEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(billRemindersEnabled: v)),
        ),
        _PrefSwitch(
          icon: Icons.credit_card_outlined,
          title: 'Parcelas de dívidas',
          subtitle: 'Lembre-me das parcelas mensais.',
          value: prefs.debtRemindersEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(debtRemindersEnabled: v)),
        ),
        _PrefSwitch(
          icon: Icons.savings_outlined,
          title: 'Metas de reserva',
          subtitle: 'Nudges mensais para contribuir nas metas.',
          value: prefs.fundNudgesEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(fundNudgesEnabled: v)),
        ),
        _PrefSwitch(
          icon: Icons.lightbulb_outline,
          title: 'Lembretes inteligentes',
          subtitle: 'Dicas contextuais baseadas em seus dados.',
          value: prefs.smartNudgesEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(smartNudgesEnabled: v)),
        ),
        _PrefSwitch(
          icon: Icons.attach_money,
          title: 'Dia de salário',
          subtitle: 'Notificação no dia em que seu salário costuma cair.',
          value: prefs.salaryReminderEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(salaryReminderEnabled: v)),
        ),
        if (prefs.salaryReminderEnabled) ...[
          _SalaryDayPicker(
            current: prefs.salaryDay,
            onChanged: (day) =>
                notifier.updatePreferences((p) => p.copyWith(salaryDay: day)),
          ),
        ],

        const Divider(height: 32),

        // ── Output ───────────────────────────────────────────────────────
        _SectionHeader(title: 'Som e Vibração'),
        _PrefSwitch(
          icon: Icons.volume_up_outlined,
          title: 'Som',
          subtitle: 'Reproduzir som nas notificações.',
          value: prefs.soundEnabled,
          onChanged: (v) =>
              notifier.updatePreferences((p) => p.copyWith(soundEnabled: v)),
        ),
        _PrefSwitch(
          icon: Icons.vibration,
          title: 'Vibração',
          subtitle: 'Vibrar ao receber notificações.',
          value: prefs.vibrationEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(vibrationEnabled: v)),
        ),

        const Divider(height: 32),

        // ── Quiet hours ──────────────────────────────────────────────────
        _SectionHeader(title: 'Horário Silencioso'),
        _PrefSwitch(
          icon: Icons.bedtime_outlined,
          title: 'Ativar horário silencioso',
          subtitle: 'Notificações fora deste período não serão entregues '
              'no horário configurado.',
          value: prefs.quietHoursEnabled,
          onChanged: (v) => notifier
              .updatePreferences((p) => p.copyWith(quietHoursEnabled: v)),
        ),
        if (prefs.quietHoursEnabled) ...[
          _QuietHoursEditor(
            startHour: prefs.quietHoursStart,
            endHour: prefs.quietHoursEnd,
            onStartChanged: (h) => notifier
                .updatePreferences((p) => p.copyWith(quietHoursStart: h)),
            onEndChanged: (h) =>
                notifier.updatePreferences((p) => p.copyWith(quietHoursEnd: h)),
          ),
        ],

        const Divider(height: 32),

        // ── Email summary ────────────────────────────────────────────────
        _SectionHeader(title: 'Resumo por e-mail'),
        _PrefSwitch(
          icon: Icons.email_outlined,
          title: 'Ativar resumo por e-mail',
          subtitle: 'Gere rascunhos semanais ou mensais com seus dados atuais.',
          value: prefs.emailOptIn,
          onChanged: (v) =>
              notifier.updatePreferences((p) => p.copyWith(emailOptIn: v)),
        ),
        if (prefs.emailOptIn) const _EmailSummaryActions(),

        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }
}

enum _EmailSummaryPeriod { weekly, monthly }

class _EmailSummaryActions extends ConsumerWidget {
  const _EmailSummaryActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rascunho local',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sem backend configurado, o Paguei? monta o resumo e abre seu app de e-mail para envio.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openSummaryDraft(
                        context,
                        ref,
                        _EmailSummaryPeriod.weekly,
                      ),
                      icon: const Icon(Icons.calendar_view_week_outlined),
                      label: const Text('Semanal'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openSummaryDraft(
                        context,
                        ref,
                        _EmailSummaryPeriod.monthly,
                      ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Mensal'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSummaryDraft(
    BuildContext context,
    WidgetRef ref,
    _EmailSummaryPeriod period,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final summary = await ref.read(dashboardSummaryProvider.future);
      final bills = await ref.read(pendingBillsProvider.future);
      final debts = await ref.read(activeDebtsStreamProvider.future);
      final funds = await ref.read(fundsStreamProvider.future);
      final title = switch (period) {
        _EmailSummaryPeriod.weekly => '[Paguei?] Resumo Semanal',
        _EmailSummaryPeriod.monthly => '[Paguei?] Resumo Mensal',
      };
      final body = _buildEmailBody(
        period: period,
        summary: summary,
        pendingBills: bills,
        activeDebts: debts,
        funds: funds,
      );
      final uri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': title,
          'body': body,
        },
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o app de e-mail.'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao gerar resumo: $e')),
      );
    }
  }

  String _buildEmailBody({
    required _EmailSummaryPeriod period,
    required DashboardSummary summary,
    required List<Bill> pendingBills,
    required List<Debt> activeDebts,
    required List<Fund> funds,
  }) {
    final now = DateTime.now();
    final dueBills = _filterDueBills(pendingBills, period, now);
    final debtTotal = activeDebts.fold<double>(
      0,
      (sum, debt) => sum + debt.remainingAmount.amount,
    );
    final fundsLines = funds.isEmpty
        ? '- Nenhum fundo cadastrado'
        : funds.map((fund) {
            final target = fund.targetAmount.amount;
            final current = fund.currentAmount.amount;
            final progress =
                target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
            return '- ${fund.name}: ${CurrencyFormatter.format(current)} de ${CurrencyFormatter.format(target)} (${(progress * 100).round()}%)';
          }).join('\n');
    final dueLines = dueBills.isEmpty
        ? '- Nenhum boleto vencendo no período'
        : dueBills.map((bill) {
            return '- ${bill.title}: ${CurrencyFormatter.format(bill.amount.amount)} vence em ${_fmtDate(bill.dueDate)}';
          }).join('\n');
    final debtLines = activeDebts.isEmpty
        ? '- Nenhuma dívida ativa'
        : activeDebts.take(5).map((debt) {
            return '- ${debt.creditorName}: ${CurrencyFormatter.format(debt.remainingAmount.amount)}';
          }).join('\n');
    final periodLabel = switch (period) {
      _EmailSummaryPeriod.weekly => 'semanal',
      _EmailSummaryPeriod.monthly => 'mensal',
    };

    return '''
Resumo $periodLabel do Paguei?
Gerado em ${_fmtDate(now)}

Saldo atual: ${CurrencyFormatter.format(summary.totalBalance.amount)}
Receitas do mês: ${CurrencyFormatter.format(summary.monthlyIncome.amount)}
Despesas do mês: ${CurrencyFormatter.format(summary.monthlyExpense.amount)}

Boletos vencendo:
$dueLines

Dívidas ativas: ${activeDebts.length} (${CurrencyFormatter.format(debtTotal)})
$debtLines

Progresso dos fundos:
$fundsLines
''';
  }

  List<Bill> _filterDueBills(
    List<Bill> bills,
    _EmailSummaryPeriod period,
    DateTime now,
  ) {
    return bills.where((bill) {
      final due = bill.dueDate;
      if (period == _EmailSummaryPeriod.weekly) {
        final cutoff = now.add(const Duration(days: 7));
        return !due.isBefore(DateTime(now.year, now.month, now.day)) &&
            !due.isAfter(cutoff);
      }
      return due.year == now.year && due.month == now.month;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _PrefSwitch extends StatelessWidget {
  const _PrefSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Hour-picker row for a single quiet-hours boundary.
class _QuietHoursEditor extends StatelessWidget {
  const _QuietHoursEditor({
    required this.startHour,
    required this.endHour,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final int startHour;
  final int endHour;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HourDropdown(
              label: 'Início',
              hour: startHour,
              onChanged: onStartChanged,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('até'),
          ),
          Expanded(
            child: _HourDropdown(
              label: 'Fim',
              hour: endHour,
              onChanged: onEndChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: hour,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        isDense: true,
      ),
      items: List.generate(24, (h) {
        final label = '${h.toString().padLeft(2, '0')}:00';
        return DropdownMenuItem(value: h, child: Text(label));
      }),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Salary-day picker — shows a dropdown for days 1–31.
class _SalaryDayPicker extends StatelessWidget {
  const _SalaryDayPicker({
    required this.current,
    required this.onChanged,
  });

  final int? current;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: DropdownButtonFormField<int>(
        initialValue: current,
        decoration: const InputDecoration(
          labelText: 'Dia do mês do salário',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        hint: const Text('Selecione o dia'),
        items: List.generate(31, (i) {
          final day = i + 1;
          return DropdownMenuItem(value: day, child: Text('Dia $day'));
        }),
        onChanged: onChanged,
      ),
    );
  }
}
