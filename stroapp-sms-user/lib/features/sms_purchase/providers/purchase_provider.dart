import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/purchase_api.dart';
import '../../../core/api/endpoints/services_api.dart';
import '../../../core/models/service.dart';
import '../../../core/models/country.dart';
import '../../../core/models/price_info.dart';
import '../../../core/models/sms_order.dart';
import '../../../core/api/api_exceptions.dart';

class PurchaseState {
  final bool isLoading;
  final List<Service> services;
  final List<Country> countries;
  final Service? selectedService;
  final Country? selectedCountry;
  final PriceInfo? price;
  final SMSOrder? order;
  final String? error;

  const PurchaseState({
    this.isLoading = false,
    this.services = const [],
    this.countries = const [],
    this.selectedService,
    this.selectedCountry,
    this.price,
    this.order,
    this.error,
  });

  PurchaseState copyWith({
    bool? isLoading,
    List<Service>? services,
    List<Country>? countries,
    Service? selectedService,
    Country? selectedCountry,
    PriceInfo? price,
    SMSOrder? order,
    String? error,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      services: services ?? this.services,
      countries: countries ?? this.countries,
      selectedService: selectedService ?? this.selectedService,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      price: price ?? this.price,
      order: order ?? this.order,
      error: error,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseApi _purchaseApi;
  final ServicesApi _servicesApi;

  PurchaseNotifier(this._purchaseApi, this._servicesApi) : super(const PurchaseState());

  Future<void> fetchServices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _servicesApi.getServices(null, 50, 0);
      final services = data.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, services: services);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الخدمات'));
    }
  }

  Future<void> fetchCountries(String service) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _servicesApi.getServiceCountries(service);
      final countries = data.map((e) => Country.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, countries: countries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الدول'));
    }
  }

  void selectService(Service service) {
    state = state.copyWith(selectedService: service, selectedCountry: null, price: null);
  }

  void selectCountry(Country country) {
    state = state.copyWith(selectedCountry: country);
  }

  Future<void> fetchPrice(String service, String country) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _purchaseApi.getPrice(service, country);
      final price = PriceInfo.fromJson(response);
      state = state.copyWith(isLoading: false, price: price);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل السعر'));
    }
  }

  Future<void> purchase(String service, String country, String provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idempotencyKey = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await _purchaseApi.purchase(service, country, provider, idempotencyKey);
      final order = SMSOrder.fromJson(response);
      state = state.copyWith(isLoading: false, order: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في الشراء'));
    }
  }

  void reset() => state = const PurchaseState();
  void clearError() => state = state.copyWith(error: null);
}

final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final purchaseApi = ref.read(purchaseApiProvider);
  final servicesApi = ref.read(servicesApiProvider);
  return PurchaseNotifier(purchaseApi, servicesApi);
});
