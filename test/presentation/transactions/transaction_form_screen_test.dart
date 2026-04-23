import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/application/transactions/create_transaction_use_case.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/categories/providers/categories_provider.dart';
import 'package:paguei/presentation/router/app_router.dart';
import 'package:paguei/presentation/theme/app_theme.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';
import 'package:paguei/presentation/transactions/transaction_form_screen.dart';

Account _buildTestAccount({String id = 'acc-1', String name = 'Nubank'}) {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: id,
    name: name,
    type: AccountType.checking,
    currentBalance: Money.zero,
    currency: 'BRL',
    isArchived: false,
    color: 0xFF1B4332,
    icon: 'account_balance',
    createdAt: now,
    updatedAt: now,
  );
}

final class _CreateTransactionCall {
  const _CreateTransactionCall({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.categoryId,
    this.notes,
  });

  final String id;
  final String accountId;
  final TransactionType type;
  final Money amount;
  final String description;
  final DateTime date;
  final String? categoryId;
  final String? notes;
}

final class _RecordingTransactionRepository implements TransactionRepository {
  final List<_CreateTransactionCall> createCalls = [];

  @override
  Future<Transaction> create({
    required String id,
    required String accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required DateTime date,
    String? categoryId,
    String? billId,
    bool isRecurring = false,
    String? recurrenceGroupId,
    String? notes,
  }) async {
    final transaction = Transaction.create(
      id: id,
      accountId: accountId,
      type: type,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      billId: billId,
      isRecurring: isRecurring,
      recurrenceGroupId: recurrenceGroupId,
      notes: notes,
    );
    createCalls.add(
      _CreateTransactionCall(
        id: id,
        accountId: accountId,
        type: type,
        amount: amount,
        description: description,
        date: date,
        categoryId: categoryId,
        notes: notes,
      ),
    );
    return transaction;
  }

  @override
  Future<Transaction> createTransfer({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required String description,
    required DateTime date,
    String? notes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Transaction>> getByAccount(String accountId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Transaction>> getByCategory(String categoryId) {
    throw UnimplementedError();
  }

  @override
  Future<Transaction?> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Transaction>> getByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Transaction>> getByMonth({
    required int year,
    required int month,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Money> getMonthlySummary({
    required int year,
    required int month,
    TransactionType? type,
    String? accountId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Transaction> update(Transaction transaction) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Transaction>> watchByMonth({
    required int year,
    required int month,
  }) {
    throw UnimplementedError();
  }
}

final class _FormHarness extends StatefulWidget {
  const _FormHarness();

  @override
  State<_FormHarness> createState() => _FormHarnessState();
}

final class _FormHarnessState extends State<_FormHarness> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push(AppRoutes.transactionNew);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

Widget _buildForm({
  List<Account>? accounts,
  _RecordingTransactionRepository? repository,
}) {
  final effectiveAccounts = accounts ?? [_buildTestAccount()];
  final effectiveRepository = repository ?? _RecordingTransactionRepository();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _FormHarness(),
      ),
      GoRoute(
        path: AppRoutes.transactionNew,
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountNew,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Novo Local Teste')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      accountsStreamProvider.overrideWith(
        (ref) => Stream.value(effectiveAccounts),
      ),
      categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
      createTransactionUseCaseProvider.overrideWith(
        (ref) => CreateTransactionUseCase(effectiveRepository),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      routerConfig: router,
    ),
  );
}

Future<void> _pumpForm(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredFields(
  WidgetTester tester, {
  String amount = '100.00',
  String description = 'Salário',
}) async {
  await tester.enterText(
    find
        .ancestor(
          of: find.text('Valor'),
          matching: find.byType(TextFormField),
        )
        .first,
    amount,
  );
  await tester.enterText(
    find
        .ancestor(
          of: find.text('Descrição'),
          matching: find.byType(TextFormField),
        )
        .first,
    description,
  );
}

Future<void> _selectAccount(WidgetTester tester, String accountName) async {
  await tester.tap(find.byType(DropdownButtonFormField<Account>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(accountName).last);
  await tester.pumpAndSettle();
}

void main() {
  group('TransactionFormScreen', () {
    testWidgets('exibe campos obrigatórios', (tester) async {
      await _pumpForm(tester, _buildForm());

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.text('Valor'), findsOneWidget);
      expect(find.text('Descrição'), findsOneWidget);
    });

    testWidgets('exibe seletor de tipo (Despesa / Receita)', (tester) async {
      await _pumpForm(tester, _buildForm());

      expect(find.text('Despesa'), findsOneWidget);
      expect(find.text('Receita'), findsOneWidget);
    });

    testWidgets('exibe seletor de data', (tester) async {
      await _pumpForm(tester, _buildForm());

      expect(find.text('Data'), findsOneWidget);
    });

    testWidgets('exibe seletor de categoria', (tester) async {
      await _pumpForm(tester, _buildForm());

      expect(find.text('Categoria (opcional)'), findsOneWidget);
    });

    testWidgets('explica de onde sai dinheiro em despesa', (tester) async {
      await _pumpForm(tester, _buildForm());

      expect(find.text('De onde saiu?'), findsOneWidget);
    });

    testWidgets('explica para onde entrou dinheiro em receita', (tester) async {
      await _pumpForm(tester, _buildForm());

      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();

      expect(find.text('Para onde entrou?'), findsOneWidget);
    });

    testWidgets('valida campo de valor vazio', (tester) async {
      await _pumpForm(tester, _buildForm());

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(find.text('Informe o valor'), findsOneWidget);
    });

    testWidgets('valida descrição vazia', (tester) async {
      await _pumpForm(tester, _buildForm());

      await tester.enterText(
        find
            .ancestor(
              of: find.text('Valor'),
              matching: find.byType(TextFormField),
            )
            .first,
        '50.00',
      );

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(find.text('Informe a descrição'), findsOneWidget);
    });

    testWidgets('título exibe "Nova transação" no modo de criação',
        (tester) async {
      await _pumpForm(tester, _buildForm());

      expect(find.text('Nova transação'), findsOneWidget);
    });

    testWidgets('exibe tipo Despesa selecionado por padrão', (tester) async {
      await _pumpForm(tester, _buildForm());

      // SegmentedButton should show Despesa as default
      final segmentedButton = find.byType(SegmentedButton<TransactionType>);
      expect(segmentedButton, findsOneWidget);
    });

    testWidgets('registra receita com conta selecionada', (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(
          accounts: [
            _buildTestAccount(id: 'acc-1', name: 'Nubank'),
            _buildTestAccount(id: 'acc-2', name: 'Itaú'),
          ],
          repository: repository,
        ),
      );

      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      await _fillRequiredFields(tester);
      await _selectAccount(tester, 'Itaú');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.single.type, TransactionType.income);
      expect(repository.createCalls.single.accountId, 'acc-2');
      expect(repository.createCalls.single.description, 'Salário');
    });

    testWidgets('mantém conta selecionada ao alternar de despesa para receita',
        (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(
          accounts: [
            _buildTestAccount(id: 'acc-1', name: 'Nubank'),
            _buildTestAccount(id: 'acc-2', name: 'Itaú'),
          ],
          repository: repository,
        ),
      );

      await _fillRequiredFields(tester, description: 'Freelance');
      await _selectAccount(tester, 'Nubank');
      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.single.type, TransactionType.income);
      expect(repository.createCalls.single.accountId, 'acc-1');
    });

    testWidgets('pré-seleciona a única conta ativa ao registrar receita',
        (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(
          accounts: [_buildTestAccount(id: 'acc-1', name: 'Nubank')],
          repository: repository,
        ),
      );

      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      await _fillRequiredFields(tester);
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.single.type, TransactionType.income);
      expect(repository.createCalls.single.accountId, 'acc-1');
    });

    testWidgets('bloqueia envio com múltiplas contas e nenhuma selecionada',
        (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(
          accounts: [
            _buildTestAccount(id: 'acc-1', name: 'Nubank'),
            _buildTestAccount(id: 'acc-2', name: 'Itaú'),
          ],
          repository: repository,
        ),
      );

      await _fillRequiredFields(tester);
      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(find.text('Escolha de onde saiu'), findsWidgets);
      expect(repository.createCalls, isEmpty);
    });

    testWidgets('sem contas exibe orientação e mantém Registrar desabilitado',
        (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(accounts: [], repository: repository),
      );

      expect(find.text('Nenhum local do dinheiro cadastrado'), findsOneWidget);
      expect(
          find.text(
              'Adicione Carteira, Nubank, Caixa ou dinheiro vivo para continuar.'),
          findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Registrar'), findsOneWidget);
      await tester.tap(find.text('Registrar'), warnIfMissed: false);
      await tester.pump();
      expect(repository.createCalls, isEmpty);
    });

    testWidgets('atalho do estado sem contas navega para nova conta',
        (tester) async {
      await _pumpForm(tester, _buildForm(accounts: []));

      await tester.tap(find.text('Adicionar local'));
      await tester.pumpAndSettle();

      expect(find.text('Novo Local Teste'), findsOneWidget);
    });

    testWidgets('registra despesa com conta selecionada', (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(
          accounts: [
            _buildTestAccount(id: 'acc-1', name: 'Nubank'),
            _buildTestAccount(id: 'acc-2', name: 'Itaú'),
          ],
          repository: repository,
        ),
      );

      await _fillRequiredFields(tester, description: 'Mercado');
      await _selectAccount(tester, 'Nubank');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.single.type, TransactionType.expense);
      expect(repository.createCalls.single.accountId, 'acc-1');
    });

    testWidgets('registra receita com conta pré-selecionada sem regressão',
        (tester) async {
      final repository = _RecordingTransactionRepository();
      await _pumpForm(
        tester,
        _buildForm(
          accounts: [_buildTestAccount(id: 'acc-1', name: 'Nubank')],
          repository: repository,
        ),
      );

      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      await _fillRequiredFields(tester, description: 'Dividendos');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.single.type, TransactionType.income);
      expect(repository.createCalls.single.accountId, 'acc-1');
      expect(repository.createCalls.single.description, 'Dividendos');
    });
  });
}
