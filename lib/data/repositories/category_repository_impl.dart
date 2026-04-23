import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/daos/categories_dao.dart';
import 'package:paguei/data/models/category_model.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/domain/repositories/category_repository.dart';

final class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._dao);

  final CategoriesDao _dao;

  @override
  Future<List<Category>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Category>> getByType(CategoryType type) async {
    final rows = await _dao.getByType(type.name);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final row = await _dao.getById(id);
    return row?.toDomain();
  }

  @override
  Stream<List<Category>> watchAll() {
    return _dao
        .watchAll()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

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
    final category = Category.create(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
      isDefault: isDefault,
      parentId: parentId,
    );

    await _dao.insertCategory(category.toCompanion());
    return category;
  }

  @override
  Future<Category> update(Category category) async {
    final exists = await _dao.getById(category.id);
    if (exists == null) {
      throw NotFoundException(
          message: 'Categoria não encontrada: ${category.id}');
    }
    await _dao.updateCategory(category.toCompanion());
    return category;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteCategory(id);
  }

  @override
  Future<bool> hasDefaultCategories() => _dao.hasDefaultCategories();

  @override
  Future<void> seedDefaults(List<Category> categories) async {
    final companions = categories.map((c) => c.toCompanion()).toList();
    await _dao.insertAll(companions);
  }
}
