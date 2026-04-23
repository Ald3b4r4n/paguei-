import 'package:drift/drift.dart' show Value;
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';

extension CategoryModelMapper on CategoriesTableData {
  Category toDomain() {
    return Category(
      id: id,
      name: name,
      type: _categoryTypeFromString(type),
      icon: icon,
      color: color,
      isDefault: isDefault,
      parentId: parentId,
      createdAt: createdAt,
    );
  }
}

extension CategoryToCompanion on Category {
  CategoriesTableCompanion toCompanion() {
    return CategoriesTableCompanion.insert(
      id: id,
      name: name,
      type: type.name,
      icon: icon,
      color: color,
      isDefault: Value(isDefault),
      parentId: Value(parentId),
      createdAt: createdAt,
    );
  }
}

CategoryType _categoryTypeFromString(String value) {
  return CategoryType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CategoryType.expense,
  );
}
