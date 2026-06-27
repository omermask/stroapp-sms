import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/user_api.dart';
import '../../../core/models/transaction.dart';
import '../../../core/api/api_exceptions.dart';

class TransactionsState {
  final bool isLoading;
  final List<Transaction> transactions;
  final String? error;

  const TransactionsState({
    this.isLoading = false,
    this.transactions = const [],
    this.error,
  });

  TransactionsState copyWith({
    bool? isLoading,
    List<Transaction>? transactions,
    String? error,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final UserApi _userApi;

  TransactionsNotifier(this._userApi) : super(const TransactionsState());

  Future<void> fetchTransactions({int limit = 20, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _userApi.getTransactions(limit, offset);
      final transactions = data.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, transactions: transactions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل المعاملات'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final userApi = ref.read(userApiProvider);
  return TransactionsNotifier(userApi);
});
