import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/support_api.dart';
import '../../../core/api/api_exceptions.dart';

class SupportState {
  final bool isLoading;
  final List<Map<String, dynamic>> tickets;
  final String? error;

  const SupportState({this.isLoading = false, this.tickets = const [], this.error});

  SupportState copyWith({bool? isLoading, List<Map<String, dynamic>>? tickets, String? error}) {
    return SupportState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      error: error,
    );
  }
}

class SupportNotifier extends StateNotifier<SupportState> {
  final SupportApi _supportApi;

  SupportNotifier(this._supportApi) : super(const SupportState());

  Future<void> fetchTickets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _supportApi.getTickets();
      state = state.copyWith(isLoading: false, tickets: data.cast<Map<String, dynamic>>());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل التذاكر'));
    }
  }

  Future<void> createTicket(String subject, String message, String category, String priority) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supportApi.createTicket(subject, message, category, priority);
      await fetchTickets();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في إنشاء التذكرة'));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((ref) {
  final supportApi = ref.read(supportApiProvider);
  return SupportNotifier(supportApi);
});
