import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<CategoriesTableData>> getAll() => select(categoriesTable).get();

  Future<List<CategoriesTableData>> getByType(String type) {
    return (select(categoriesTable)
          ..where((t) => t.type.equals(type) | t.type.equals('both')))
        .get();
  }

  Future<CategoriesTableData?> getById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<CategoriesTableData>> watchAll() =>
      select(categoriesTable).watch();

  Future<void> insertCategory(CategoriesTableCompanion companion) {
    return into(categoriesTable).insert(companion);
  }

  Future<void> insertAll(List<CategoriesTableCompanion> companions) async {
    await batch((b) => b.insertAll(categoriesTable, companions));
  }

  Future<bool> updateCategory(CategoriesTableCompanion companion) {
    return update(categoriesTable).replace(companion);
  }

  Future<int> deleteCategory(String id) {
    return (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> hasDefaultCategories() async {
    final query = select(categoriesTable)
      ..where((t) => t.isDefault.equals(true))
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result != null;
  }
}
