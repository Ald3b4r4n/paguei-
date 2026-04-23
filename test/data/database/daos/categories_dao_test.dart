import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/categories_dao.dart';

import '../../../helpers/drift_test_helpers.dart';

CategoriesTableCompanion _buildCompanion({
  String id = 'cat-1',
  String name = 'Alimentação',
  String type = 'expense',
  String icon = 'food',
  int color = 0xFF4CAF50,
  bool isDefault = false,
  String? parentId,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return CategoriesTableCompanion.insert(
    id: id,
    name: name,
    type: type,
    icon: icon,
    color: color,
    isDefault: Value(isDefault),
    parentId: Value(parentId),
    createdAt: now,
  );
}

void main() {
  late AppDatabase db;
  late CategoriesDao dao;

  setUp(() {
    db = buildInMemoryDatabase();
    dao = CategoriesDao(db);
  });

  tearDown(() => db.close());

  group('CategoriesDao — CRUD', () {
    test('insere e recupera categoria por id', () async {
      await dao.insertCategory(_buildCompanion());

      final category = await dao.getById('cat-1');
      expect(category, isNotNull);
      expect(category!.name, equals('Alimentação'));
      expect(category.type, equals('expense'));
      expect(category.icon, equals('food'));
    });

    test('getAll retorna todas as categorias', () async {
      await dao
          .insertCategory(_buildCompanion(id: 'cat-1', name: 'Alimentação'));
      await dao
          .insertCategory(_buildCompanion(id: 'cat-2', name: 'Transporte'));

      final categories = await dao.getAll();
      final inserted =
          categories.where((c) => c.id.startsWith('cat-')).toList();
      expect(inserted.length, equals(2));
    });

    test('getByType filtra por tipo expense', () async {
      await dao.insertCategory(
          _buildCompanion(id: 'cat-1', name: 'Alimentação', type: 'expense'));
      await dao.insertCategory(
          _buildCompanion(id: 'cat-2', name: 'Salário', type: 'income'));

      final expenses = await dao.getByType('expense');
      final inserted = expenses.where((c) => c.id.startsWith('cat-')).toList();
      expect(inserted.length, equals(1));
      expect(inserted.first.name, equals('Alimentação'));
    });

    test('getByType filtra por tipo income', () async {
      await dao.insertCategory(
          _buildCompanion(id: 'cat-1', name: 'Alimentação', type: 'expense'));
      await dao.insertCategory(
          _buildCompanion(id: 'cat-2', name: 'Salário', type: 'income'));

      final incomes = await dao.getByType('income');
      final inserted = incomes.where((c) => c.id.startsWith('cat-')).toList();
      expect(inserted.length, equals(1));
      expect(inserted.first.name, equals('Salário'));
    });

    test('getByType inclui categorias do tipo both', () async {
      await dao.insertCategory(
          _buildCompanion(id: 'cat-1', name: 'Outros', type: 'both'));

      final expenses = await dao.getByType('expense');
      final inserted = expenses.where((c) => c.id == 'cat-1').toList();
      expect(inserted.length, equals(1));
      expect(inserted.first.name, equals('Outros'));
    });

    test('atualiza categoria via updateCategory', () async {
      await dao.insertCategory(_buildCompanion());

      final now = DateTime.utc(2026, 4, 19);
      await dao.updateCategory(
        CategoriesTableCompanion(
          id: const Value('cat-1'),
          name: const Value('Saúde'),
          type: const Value('expense'),
          icon: const Value('health'),
          color: const Value(0xFFE91E63),
          isDefault: const Value(false),
          createdAt: Value(now),
        ),
      );

      final updated = await dao.getById('cat-1');
      expect(updated!.name, equals('Saúde'));
      expect(updated.icon, equals('health'));
    });

    test('deleteCategory remove a categoria', () async {
      await dao.insertCategory(_buildCompanion());
      await dao.deleteCategory('cat-1');

      final category = await dao.getById('cat-1');
      expect(category, isNull);
    });
  });

  group('CategoriesDao — seed', () {
    test('hasDefaultCategories retorna false quando vazio', () async {
      final existing = await dao.getAll();
      for (final c in existing) {
        await dao.deleteCategory(c.id);
      }

      final hasDefaults = await dao.hasDefaultCategories();
      expect(hasDefaults, isFalse);
    });

    test('hasDefaultCategories retorna true após inserir categoria padrão',
        () async {
      await dao.insertCategory(_buildCompanion(isDefault: true));

      final hasDefaults = await dao.hasDefaultCategories();
      expect(hasDefaults, isTrue);
    });

    test('insertAll insere múltiplas categorias em batch', () async {
      final existing = await dao.getAll();
      for (final c in existing) {
        await dao.deleteCategory(c.id);
      }

      final companions = [
        _buildCompanion(id: 'cat-1', name: 'Alimentação', isDefault: true),
        _buildCompanion(
            id: 'cat-2', name: 'Salário', type: 'income', isDefault: true),
        _buildCompanion(id: 'cat-3', name: 'Transporte', isDefault: true),
      ];

      await dao.insertAll(companions);

      final categories = await dao.getAll();
      expect(categories.length, equals(3));
    });

    test('AppDatabase seeds 14 categorias padrão ao criar banco', () async {
      // In-memory database triggers onCreate which calls _seedDefaultCategories
      final categories = await dao.getAll();
      // The seeding happens in onCreate — in-memory db with NativeDatabase.memory()
      // triggers onCreate, so we should have 14 default categories
      expect(categories.length, equals(14));
      expect(categories.every((c) => c.isDefault), isTrue);
    });
  });

  group('CategoriesDao — stream reativo', () {
    test('watchAll emite lista inicial', () async {
      await dao.insertCategory(_buildCompanion());

      final list = await dao.watchAll().first;
      expect(list.length, greaterThanOrEqualTo(1));
      expect(list.any((c) => c.name == 'Alimentação'), isTrue);
    });

    test('watchAll emite nova lista após insert', () async {
      final stream = dao.watchAll();

      await dao.insertCategory(_buildCompanion(id: 'cat-new', name: 'Novo'));

      final list = await stream.first;
      expect(list.any((c) => c.name == 'Novo'), isTrue);
    });
  });
}
