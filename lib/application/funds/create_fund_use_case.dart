import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:uuid/uuid.dart';

final class CreateFundUseCase {
  const CreateFundUseCase(this._repository);

  final FundRepository _repository;

  Future<Fund> execute({
    required String name,
    required FundType type,
    required Money targetAmount,
    int color = 0xFF1B4332,
    String icon = 'savings',
    DateTime? targetDate,
    String? notes,
  }) {
    return _repository.create(
      id: const Uuid().v4(),
      name: name,
      type: type,
      targetAmount: targetAmount,
      color: color,
      icon: icon,
      targetDate: targetDate,
      notes: notes,
    );
  }
}
