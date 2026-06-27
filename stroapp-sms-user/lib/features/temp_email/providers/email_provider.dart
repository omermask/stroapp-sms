import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/email_api.dart';
import '../../../core/api/api_exceptions.dart';

class EmailState {
  final bool isLoading;
  final String? emailAddress;
  final List<Map<String, dynamic>> messages;
  final String? error;

  const EmailState({this.isLoading = false, this.emailAddress, this.messages = const [], this.error});

  EmailState copyWith({bool? isLoading, String? emailAddress, List<Map<String, dynamic>>? messages, String? error}) {
    return EmailState(
      isLoading: isLoading ?? this.isLoading,
      emailAddress: emailAddress ?? this.emailAddress,
      messages: messages ?? this.messages,
      error: error,
    );
  }
}

class EmailNotifier extends StateNotifier<EmailState> {
  final EmailApi _emailApi;

  EmailNotifier(this._emailApi) : super(const EmailState());

  Future<void> fetchTempEmail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _emailApi.getTempEmail();
      state = state.copyWith(isLoading: false, emailAddress: response['email'] as String?);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> fetchMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _emailApi.getTempEmailMessages();
      state = state.copyWith(isLoading: false, messages: data.cast<Map<String, dynamic>>());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ'));
    }
  }

  Future<void> deleteEmail() async {
    try {
      await _emailApi.deleteTempEmail();
      state = state.copyWith(emailAddress: null, messages: []);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(error: null);
}

final emailProvider = StateNotifierProvider<EmailNotifier, EmailState>((ref) {
  final emailApi = ref.read(emailApiProvider);
  return EmailNotifier(emailApi);
});
