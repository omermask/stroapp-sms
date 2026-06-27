import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/services_api.dart';
import '../../../core/api/endpoints/availability_api.dart';
import '../../../core/models/service.dart';
import '../../../core/api/api_exceptions.dart';

class HomeState {
  final bool isLoading;
  final List<Service> services;
  final List<String> categories;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.services = const [],
    this.categories = const [],
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    List<Service>? services,
    List<String>? categories,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      services: services ?? this.services,
      categories: categories ?? this.categories,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ServicesApi _servicesApi;
  final AvailabilityApi _availabilityApi;

  HomeNotifier(this._servicesApi, this._availabilityApi) : super(const HomeState());

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

  Future<void> fetchCategories() async {
    try {
      final data = await _servicesApi.getCategories();
      final categories = data.cast<String>();
      state = state.copyWith(categories: categories);
    } catch (_) {}
  }

  Future<void> fetchTopServices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _availabilityApi.getTopServices(10);
      final services = data.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, services: services);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الخدمات'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final servicesApi = ref.read(servicesApiProvider);
  final availabilityApi = ref.read(availabilityApiProvider);
  return HomeNotifier(servicesApi, availabilityApi);
});
