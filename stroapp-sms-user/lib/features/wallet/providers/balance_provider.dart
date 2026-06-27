import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/user_api.dart';
import '../../../core/models/balance.dart';
import '../../../core/api/api_exceptions.dart';

class BalanceState {
  final bool isLoading;
  final Balance? balance;
  final String? error;

  const BalanceState({this.isLoading = false, this.balance, this.error});

  BalanceState copyWith({bool? isLoading, Balance? balance, String? error}) {
    return BalanceState(
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
      error: error,
    );
  }
}

class BalanceNotifier extends StateNotifier<BalanceState> {
  final UserApi _userApi;

  BalanceNotifier(this._userApi) : super(const BalanceState());

  Future<void> fetchBalance() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _userApi.getBalance();
      final balance = Balance.fromJson(response);
      state = state.copyWith(isLoading: false, balance: balance);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الرصيد'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {
  final userApi = ref.read(userApiProvider);
  return BalanceNotifier(userApi);
});
