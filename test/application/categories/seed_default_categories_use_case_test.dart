import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/categories/seed_default_categories_use_case.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/domain/repositories/category_repository.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [];

  @override
  Future<List<Category>> getAll() async => List.unmodifiable(_categories);

  @override
  Future<List<Category>> getByType(CategoryType type) async =>
      _categories.where((c) => c.type == type).toList();

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
      createdAt: DateTime.now().toUtc(),
    );
    _categories.add(cat);
    return cat;
  }

  @override
  Future<Category> update(Category category) async => category;

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
  late SeedDefaultCategoriesUseCase useCase;
  late _FakeCategoryRepository repository;

  setUp(() {
    repository = _FakeCategoryRepository();
    useCase = SeedDefaultCategoriesUseCase(repository);
  });

  group('SeedDefaultCategoriesUseCase', () {
    test('insere 14 categorias padrão quando repositório está vazio', () async {
      await useCase.execute();

      final categories = await repository.getAll();
      expect(categories.length, equals(14));
    });

    test('todas as categorias padrão têm isDefault = true', () async {
      await useCase.execute();

      final categories = await repository.getAll();
      expect(categories.every((c) => c.isDefault), isTrue);
    });

    test('inclui 10 categorias de despesa', () async {
      await useCase.execute();

      final expenses = await repository.getByType(CategoryType.expense);
      expect(expenses.length, equals(10));
    });

    test('inclui 4 categorias de receita', () async {
      await useCase.execute();

      final incomes = await repository.getByType(CategoryType.income);
      expect(incomes.length, equals(4));
    });

    test('não faz seed quando categorias padrão já existem', () async {
      await useCase.execute(); // primeiro seed
      await useCase.execute(); // segundo seed — deve ser ignorado

      final categories = await repository.getAll();
      expect(categories.length, equals(14)); // sem duplicatas
    });

    test('defaultCategoryCount retorna 14', () {
      expect(SeedDefaultCategoriesUseCase.defaultCategoryCount, equals(14));
    });

    test('inclui categoria Alimentação', () async {
      await useCase.execute();

      final categories = await repository.getAll();
      expect(
        categories.any((c) => c.name == 'Alimentação'),
        isTrue,
      );
    });

    test('inclui categoria Salário', () async {
      await useCase.execute();

      final categories = await repository.getAll();
      expect(
        categories.any((c) => c.name == 'Salário'),
        isTrue,
      );
    });
  });
}
