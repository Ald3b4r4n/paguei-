import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/domain/repositories/category_repository.dart';

final class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> execute({CategoryType? type}) {
    if (type != null) {
      return _repository.getByType(type);
    }
    return _repository.getAll();
  }

  Stream<List<Category>> watch() => _repository.watchAll();
}
