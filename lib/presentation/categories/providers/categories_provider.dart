import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/categories/get_categories_use_case.dart';
import 'package:paguei/application/categories/seed_default_categories_use_case.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/categories_dao.dart';
import 'package:paguei/data/repositories/category_repository_impl.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoriesDao(db);
});

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoriesDaoProvider));
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});

final seedDefaultCategoriesUseCaseProvider =
    Provider<SeedDefaultCategoriesUseCase>((ref) {
  return SeedDefaultCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Category streams — reactive lists for UI
// ---------------------------------------------------------------------------

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(getCategoriesUseCaseProvider).watch();
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref
      .watch(getCategoriesUseCaseProvider)
      .execute(type: CategoryType.expense);
});

final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref
      .watch(getCategoriesUseCaseProvider)
      .execute(type: CategoryType.income);
});
