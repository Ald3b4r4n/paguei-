import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';

Category buildTestCategory({
  String id = 'cat-test-1',
  String name = 'Alimentação',
  CategoryType type = CategoryType.expense,
  String icon = 'food',
  int color = 0xFF4CAF50,
  bool isDefault = false,
  String? parentId,
}) {
  return Category(
    id: id,
    name: name,
    type: type,
    icon: icon,
    color: color,
    isDefault: isDefault,
    parentId: parentId,
    createdAt: DateTime.utc(2026, 4, 19),
  );
}

void main() {
  group('Category — criação válida', () {
    test('cria categoria com campos mínimos obrigatórios', () {
      final category = buildTestCategory();

      expect(category.id, equals('cat-test-1'));
      expect(category.name, equals('Alimentação'));
      expect(category.type, equals(CategoryType.expense));
      expect(category.icon, equals('food'));
      expect(category.color, equals(0xFF4CAF50));
      expect(category.isDefault, isFalse);
      expect(category.parentId, isNull);
    });

    test('Category.create() com nome válido funciona', () {
      final category = Category.create(
        id: 'cat-1',
        name: 'Transporte',
        type: CategoryType.expense,
        icon: 'transport',
        color: 0xFF2196F3,
      );

      expect(category.name, equals('Transporte'));
      expect(category.isDefault, isFalse);
    });

    test('Category.create() com isDefault = true cria categoria padrão', () {
      final category = Category.create(
        id: 'cat-salary',
        name: 'Salário',
        type: CategoryType.income,
        icon: 'salary',
        color: 0xFF1B4332,
        isDefault: true,
      );

      expect(category.isDefault, isTrue);
      expect(category.type, equals(CategoryType.income));
    });

    test('Category.create() com parentId define subcategoria', () {
      final category = Category.create(
        id: 'cat-sub',
        name: 'Restaurante',
        type: CategoryType.expense,
        icon: 'restaurant',
        color: 0xFF4CAF50,
        parentId: 'cat-food',
      );

      expect(category.parentId, equals('cat-food'));
    });

    test('CategoryType.both permite uso em receita e despesa', () {
      final category = buildTestCategory(type: CategoryType.both);
      expect(category.type, equals(CategoryType.both));
    });
  });

  group('Category — validação', () {
    test('nome vazio lança ValidationException', () {
      expect(
        () => Category.create(
          id: 'cat-1',
          name: '',
          type: CategoryType.expense,
          icon: 'food',
          color: 0xFF4CAF50,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nome somente espaços lança ValidationException', () {
      expect(
        () => Category.create(
          id: 'cat-1',
          name: '   ',
          type: CategoryType.expense,
          icon: 'food',
          color: 0xFF4CAF50,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nome com mais de 80 caracteres lança ValidationException', () {
      expect(
        () => Category.create(
          id: 'cat-1',
          name: 'A' * 81,
          type: CategoryType.expense,
          icon: 'food',
          color: 0xFF4CAF50,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nome com exatamente 80 caracteres é válido', () {
      final category = Category.create(
        id: 'cat-1',
        name: 'A' * 80,
        type: CategoryType.expense,
        icon: 'food',
        color: 0xFF4CAF50,
      );
      expect(category.name.length, equals(80));
    });
  });

  group('Category — copyWith', () {
    test('copyWith altera apenas os campos especificados', () {
      final category = buildTestCategory();
      final updated = category.copyWith(name: 'Saúde');

      expect(updated.name, equals('Saúde'));
      expect(updated.id, equals(category.id));
      expect(updated.type, equals(category.type));
    });

    test('copyWith sem argumentos retorna objeto com mesmos valores', () {
      final category = buildTestCategory();
      final copy = category.copyWith();

      expect(copy.id, equals(category.id));
      expect(copy.name, equals(category.name));
      expect(copy.type, equals(category.type));
    });

    test('copyWith pode alterar type', () {
      final category = buildTestCategory(type: CategoryType.expense);
      final updated = category.copyWith(type: CategoryType.income);

      expect(updated.type, equals(CategoryType.income));
    });
  });

  group('Category — igualdade', () {
    test('categorias com mesmo id são iguais', () {
      final c1 = buildTestCategory(name: 'Alimentação');
      final c2 = buildTestCategory(name: 'Alimentação');
      expect(c1, equals(c2));
    });

    test('categorias com ids diferentes não são iguais', () {
      final c1 = buildTestCategory(id: 'cat-1');
      final c2 = buildTestCategory(id: 'cat-2');
      expect(c1, isNot(equals(c2)));
    });

    test('hashCode é consistente para mesmos valores', () {
      final c1 = buildTestCategory();
      final c2 = buildTestCategory();
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('CategoryType — labels', () {
    test('income tem label correto', () {
      expect(CategoryType.income.label, equals('Receita'));
    });

    test('expense tem label correto', () {
      expect(CategoryType.expense.label, equals('Despesa'));
    });

    test('both tem label correto', () {
      expect(CategoryType.both.label, equals('Ambos'));
    });
  });
}
