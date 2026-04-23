import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/presentation/categories/providers/categories_provider.dart';
import 'package:paguei/presentation/shared/widgets/category_picker_sheet.dart';

List<Category> _buildCategories() {
  final now = DateTime.utc(2026, 4, 19);
  return [
    Category(
      id: 'cat-1',
      name: 'Alimentação',
      type: CategoryType.expense,
      icon: 'food',
      color: 0xFF4CAF50,
      isDefault: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-2',
      name: 'Transporte',
      type: CategoryType.expense,
      icon: 'transport',
      color: 0xFF2196F3,
      isDefault: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-3',
      name: 'Salário',
      type: CategoryType.income,
      icon: 'salary',
      color: 0xFF1B4332,
      isDefault: true,
      createdAt: now,
    ),
  ];
}

void main() {
  group('CategoryPickerSheet', () {
    testWidgets('exibe lista de categorias', (tester) async {
      final categories = _buildCategories();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(categories),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPickerSheet(
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Alimentação'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('Salário'), findsOneWidget);
    });

    testWidgets('exibe estado de loading enquanto carrega', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPickerSheet(
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('filtra categorias por tipo expense', (tester) async {
      final categories = _buildCategories();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(categories),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPickerSheet(
                filter: CategoryType.expense,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Alimentação'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('Salário'), findsNothing);
    });

    testWidgets('marca categoria selecionada com ícone de check',
        (tester) async {
      final categories = _buildCategories();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(categories),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPickerSheet(
                selectedId: 'cat-1',
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('chama onSelected ao tocar em categoria', (tester) async {
      final categories = _buildCategories();
      Category? selected;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(categories),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPickerSheet(
                onSelected: (cat) => selected = cat,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Alimentação'));

      expect(selected, isNotNull);
      expect(selected!.id, equals('cat-1'));
    });

    testWidgets('exibe mensagem quando lista está vazia', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(<Category>[]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryPickerSheet(
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Nenhuma categoria disponível.'), findsOneWidget);
    });
  });
}
