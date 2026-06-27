import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/rentals_api.dart';
import '../../../core/models/rental.dart';
import '../../../core/api/api_exceptions.dart';

class RentalsState {
  final bool isLoading;
  final List<Rental> rentals;
  final String? error;

  const RentalsState({this.isLoading = false, this.rentals = const [], this.error});

  RentalsState copyWith({bool? isLoading, List<Rental>? rentals, String? error}) {
    return RentalsState(
      isLoading: isLoading ?? this.isLoading,
      rentals: rentals ?? this.rentals,
      error: error,
    );
  }
}

class RentalsNotifier extends StateNotifier<RentalsState> {
  final RentalsApi _rentalsApi;

  RentalsNotifier(this._rentalsApi) : super(const RentalsState());

  Future<void> fetchRentals({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _rentalsApi.getRentals(status);
      final rentals = data.map((e) => Rental.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, rentals: rentals);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الإيجارات'));
    }
  }

  Future<void> createRental(String service, String country, int hours, bool autoExtend) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _rentalsApi.createRental(service, country, hours, autoExtend);
      await fetchRentals();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في إنشاء الإيجار'));
    }
  }

  Future<void> cancelRental(String rentalId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _rentalsApi.cancelRental(rentalId);
      await fetchRentals();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في إلغاء الإيجار'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final rentalsProvider = StateNotifierProvider<RentalsNotifier, RentalsState>((ref) {
  final rentalsApi = ref.read(rentalsApiProvider);
  return RentalsNotifier(rentalsApi);
});
