import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/funds/contribute_fund_use_case.dart';
import 'package:paguei/application/funds/create_fund_use_case.dart';
import 'package:paguei/application/funds/get_funds_use_case.dart';
import 'package:paguei/application/funds/withdraw_from_fund_use_case.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/funds_dao.dart';
import 'package:paguei/data/repositories/fund_repository_impl.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

final fundsDaoProvider = Provider<FundsDao>((ref) {
  return FundsDao(ref.watch(appDatabaseProvider));
});

final fundRepositoryProvider = Provider<FundRepositoryImpl>((ref) {
  return FundRepositoryImpl(ref.watch(fundsDaoProvider));
});

final createFundUseCaseProvider = Provider<CreateFundUseCase>((ref) {
  return CreateFundUseCase(ref.watch(fundRepositoryProvider));
});

final getFundsUseCaseProvider = Provider<GetFundsUseCase>((ref) {
  return GetFundsUseCase(ref.watch(fundRepositoryProvider));
});

final contributeFundUseCaseProvider = Provider<ContributeFundUseCase>((ref) {
  return ContributeFundUseCase(ref.watch(fundRepositoryProvider));
});

final withdrawFromFundUseCaseProvider =
    Provider<WithdrawFromFundUseCase>((ref) {
  return WithdrawFromFundUseCase(ref.watch(fundRepositoryProvider));
});

final fundsStreamProvider = StreamProvider<List<Fund>>((ref) {
  return ref.watch(getFundsUseCaseProvider).watch();
});

class FundNotifier extends Notifier<AsyncValue<List<Fund>>> {
  @override
  AsyncValue<List<Fund>> build() {
    ref.watch(fundsStreamProvider).whenData(
          (funds) => state = AsyncData(funds),
        );
    return const AsyncLoading();
  }

  Future<void> createFund({
    required String name,
    required FundType type,
    required Money targetAmount,
    int color = 0xFF1B4332,
    String icon = 'savings',
    DateTime? targetDate,
    String? notes,
  }) async {
    await ref.read(createFundUseCaseProvider).execute(
          name: name,
          type: type,
          targetAmount: targetAmount,
          color: color,
          icon: icon,
          targetDate: targetDate,
          notes: notes,
        );
  }

  Future<void> contribute(String fundId, Money amount) async {
    await ref.read(contributeFundUseCaseProvider).execute(
          fundId: fundId,
          amount: amount,
        );
  }

  Future<void> withdraw(String fundId, Money amount) async {
    await ref.read(withdrawFromFundUseCaseProvider).execute(
          fundId: fundId,
          amount: amount,
        );
  }

  Future<void> deleteFund(String id) async {
    await ref.read(fundRepositoryProvider).delete(id);
  }
}

final fundNotifierProvider =
    NotifierProvider<FundNotifier, AsyncValue<List<Fund>>>(FundNotifier.new);
