import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getAll();

  Future<List<Category>> getByType(CategoryType type);

  Future<Category?> getById(String id);

  Stream<List<Category>> watchAll();

  Future<Category> create({
    required String id,
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
    bool isDefault,
    String? parentId,
  });

  Future<Category> update(Category category);

  Future<void> delete(String id);

  Future<bool> hasDefaultCategories();

  Future<void> seedDefaults(List<Category> categories);
}
