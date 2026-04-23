import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/category_type.dart';

final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.createdAt,
    this.parentId,
  });

  factory Category.create({
    required String id,
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
    bool isDefault = false,
    String? parentId,
  }) {
    if (name.trim().isEmpty) {
      throw const ValidationException(
          message: 'Nome da categoria não pode ser vazio.');
    }
    if (name.length > 80) {
      throw const ValidationException(
          message: 'Nome da categoria não pode ter mais de 80 caracteres.');
    }

    return Category(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
      isDefault: isDefault,
      parentId: parentId,
      createdAt: DateTime.now().toUtc(),
    );
  }

  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final int color;
  final bool isDefault;
  final String? parentId;
  final DateTime createdAt;

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? icon,
    int? color,
    bool? isDefault,
    String? parentId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
