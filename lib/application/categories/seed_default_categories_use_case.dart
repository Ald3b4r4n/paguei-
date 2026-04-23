import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/domain/repositories/category_repository.dart';

final class SeedDefaultCategoriesUseCase {
  const SeedDefaultCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  static const _defaultCategories = [
    _CategorySeed(
        'cat_food', 'Alimentação', CategoryType.expense, 'food', 0xFF4CAF50),
    _CategorySeed('cat_transport', 'Transporte', CategoryType.expense,
        'transport', 0xFF2196F3),
    _CategorySeed(
        'cat_housing', 'Moradia', CategoryType.expense, 'housing', 0xFF795548),
    _CategorySeed(
        'cat_health', 'Saúde', CategoryType.expense, 'health', 0xFFE91E63),
    _CategorySeed('cat_education', 'Educação', CategoryType.expense,
        'education', 0xFF9C27B0),
    _CategorySeed(
        'cat_leisure', 'Lazer', CategoryType.expense, 'leisure', 0xFFFF9800),
    _CategorySeed('cat_clothing', 'Vestuário', CategoryType.expense, 'clothing',
        0xFF00BCD4),
    _CategorySeed('cat_subscriptions', 'Assinaturas', CategoryType.expense,
        'subscriptions', 0xFF673AB7),
    _CategorySeed(
        'cat_taxes', 'Impostos', CategoryType.expense, 'taxes', 0xFF607D8B),
    _CategorySeed(
        'cat_other_exp', 'Outros', CategoryType.expense, 'other', 0xFF9E9E9E),
    _CategorySeed(
        'cat_salary', 'Salário', CategoryType.income, 'salary', 0xFF1B4332),
    _CategorySeed('cat_freelance', 'Freelance', CategoryType.income,
        'freelance', 0xFF52B788),
    _CategorySeed('cat_investments', 'Investimentos', CategoryType.income,
        'investments', 0xFF2D6A4F),
    _CategorySeed(
        'cat_other_inc', 'Outros', CategoryType.income, 'other', 0xFF74C69D),
  ];

  Future<void> execute() async {
    final alreadySeeded = await _repository.hasDefaultCategories();
    if (alreadySeeded) return;

    final categories = _defaultCategories
        .map(
          (seed) => Category(
            id: seed.id,
            name: seed.name,
            type: seed.type,
            icon: seed.icon,
            color: seed.color,
            isDefault: true,
            createdAt: DateTime.now().toUtc(),
          ),
        )
        .toList();

    await _repository.seedDefaults(categories);
  }

  static int get defaultCategoryCount => _defaultCategories.length;
}

class _CategorySeed {
  const _CategorySeed(this.id, this.name, this.type, this.icon, this.color);

  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final int color;
}
