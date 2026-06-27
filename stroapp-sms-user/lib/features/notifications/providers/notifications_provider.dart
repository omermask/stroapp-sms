import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/notifications_api.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/api/api_exceptions.dart';

class NotificationsState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsApi _notificationsApi;

  NotificationsNotifier(this._notificationsApi) : super(const NotificationsState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _notificationsApi.getNotifications(50, 0);
      final notifications = data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      final unreadCount = await _notificationsApi.getUnreadCount();
      state = state.copyWith(isLoading: false, notifications: notifications, unreadCount: unreadCount);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الإشعارات'));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _notificationsApi.markAllRead();
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(error: null);
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final notificationsApi = ref.read(notificationsApiProvider);
  return NotificationsNotifier(notificationsApi);
});
