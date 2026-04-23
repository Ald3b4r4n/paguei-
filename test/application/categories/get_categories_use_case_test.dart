import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/categories/get_categories_use_case.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/domain/repositories/category_repository.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [];

  @override
  Future<List<Category>> getAll() async => List.unmodifiable(_categories);

  @override
  Future<List<Category>> getByType(CategoryType type) async => _categories
      .where((c) => c.type == type || c.type == CategoryType.both)
      .toList();

  @override
  Future<Category?> getById(String id) async =>
      _categories.where((c) => c.id == id).firstOrNull;

  @override
  Stream<List<Category>> watchAll() =>
      Stream.value(List.unmodifiable(_categories));

  @override
  Future<Category> create({
    required String id,
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
    bool isDefault = false,
    String? parentId,
  }) async {
    final cat = Category(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
      isDefault: isDefault,
      parentId: parentId,
      createdAt: DateTime.now().toUtc(),
    );
    _categories.add(cat);
    return cat;
  }

  @override
  Future<Category> update(Category category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _categories[idx] = category;
    return category;
  }

  @override
  Future<void> delete(String id) async =>
      _categories.removeWhere((c) => c.id == id);

  @override
  Future<bool> hasDefaultCategories() async =>
      _categories.any((c) => c.isDefault);

  @override
  Future<void> seedDefaults(List<Category> categories) async =>
      _categories.addAll(categories);
}

void main() {
  late GetCategoriesUseCase useCase;
  late _FakeCategoryRepository repository;

  setUp(() {
    repository = _FakeCategoryRepository();
    useCase = GetCategoriesUseCase(repository);
  });

  group('GetCategoriesUseCase', () {
    test('retorna lista vazia quando não há categorias', () async {
      final categories = await useCase.execute();
      expect(categories, isEmpty);
    });

    test('retorna todas as categorias sem filtro', () async {
      await repository.create(
        id: 'cat-1',
        name: 'Alimentação',
        type: CategoryType.expense,
        icon: 'food',
        color: 0xFF4CAF50,
      );
      await repository.create(
        id: 'cat-2',
        name: 'Salário',
        type: CategoryType.income,
        icon: 'salary',
        color: 0xFF1B4332,
      );

      final categories = await useCase.execute();
      expect(categories.length, equals(2));
    });

    test('filtra por tipo expense', () async {
      await repository.create(
        id: 'cat-1',
        name: 'Alimentação',
        type: CategoryType.expense,
        icon: 'food',
        color: 0xFF4CAF50,
      );
      await repository.create(
        id: 'cat-2',
        name: 'Salário',
        type: CategoryType.income,
        icon: 'salary',
        color: 0xFF1B4332,
      );

      final expenses = await useCase.execute(type: CategoryType.expense);
      expect(expenses.length, equals(1));
      expect(expenses.first.name, equals('Alimentação'));
    });

    test('filtra por tipo income', () async {
      await repository.create(
        id: 'cat-1',
        name: 'Alimentação',
        type: CategoryType.expense,
        icon: 'food',
        color: 0xFF4CAF50,
      );
      await repository.create(
        id: 'cat-2',
        name: 'Salário',
        type: CategoryType.income,
        icon: 'salary',
        color: 0xFF1B4332,
      );

      final incomes = await useCase.execute(type: CategoryType.income);
      expect(incomes.length, equals(1));
      expect(incomes.first.name, equals('Salário'));
    });

    test('watch() emite stream reativo', () async {
      await repository.create(
        id: 'cat-1',
        name: 'Lazer',
        type: CategoryType.expense,
        icon: 'leisure',
        color: 0xFFFF9800,
      );

      final stream = useCase.watch();
      final list = await stream.first;
      expect(list.length, equals(1));
      expect(list.first.name, equals('Lazer'));
    });
  });
}
