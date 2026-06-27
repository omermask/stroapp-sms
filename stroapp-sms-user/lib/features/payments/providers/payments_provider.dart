import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/payments_api.dart';
import '../../../core/api/api_exceptions.dart';

class PaymentsState {
  final bool isLoading;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> history;
  final String? error;

  const PaymentsState({this.isLoading = false, this.products = const [], this.history = const [], this.error});

  PaymentsState copyWith({bool? isLoading, List<Map<String, dynamic>>? products, List<Map<String, dynamic>>? history, String? error}) {
    return PaymentsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      history: history ?? this.history,
      error: error,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final PaymentsApi _paymentsApi;

  PaymentsNotifier(this._paymentsApi) : super(const PaymentsState());

  Future<void> fetchProducts(String provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _paymentsApi.getProducts(provider);
      state = state.copyWith(isLoading: false, products: data.cast<Map<String, dynamic>>());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _paymentsApi.getPaymentHistory(50, 0);
      state = state.copyWith(isLoading: false, history: data.cast<Map<String, dynamic>>());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  final paymentsApi = ref.read(paymentsApiProvider);
  return PaymentsNotifier(paymentsApi);
});
