import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/purchase_api.dart';
import '../../../core/models/sms_order.dart';
import '../../../core/api/api_exceptions.dart';

class OrdersState {
  final bool isLoading;
  final List<SMSOrder> orders;
  final String? error;

  const OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<SMSOrder>? orders,
    String? error,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final PurchaseApi _purchaseApi;

  OrdersNotifier(this._purchaseApi) : super(const OrdersState());

  Future<void> fetchOrders({String? status, int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _purchaseApi.getOrders(status, limit);
      final orders = data.map((e) => SMSOrder.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الطلبات'));
    }
  }

  Future<void> cancelOrder(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _purchaseApi.cancelOrder(orderId);
      await fetchOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في إلغاء الطلب'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final purchaseApi = ref.read(purchaseApiProvider);
  return OrdersNotifier(purchaseApi);
});
