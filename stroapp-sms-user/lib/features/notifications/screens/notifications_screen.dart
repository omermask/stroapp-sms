import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/notifications_api.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

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
  final NotificationsApi _api;

  NotificationsNotifier(this._api) : super(const NotificationsState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getNotifications(50, 0);
      final list = data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      final unread = await _api.getUnreadCount();
      state = state.copyWith(isLoading: false, notifications: list, unreadCount: unread);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      state = state.copyWith(unreadCount: 0);
      await fetchNotifications();
    } catch (_) {}
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final api = ref.read(notificationsApiProvider);
  return NotificationsNotifier(api);
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'payment':
      case 'payment_success':
        return QasehIcons.wallet_curved;
      case 'sms':
      case 'sms_received':
        return QasehIcons.message_curved;
      case 'support':
      case 'ticket_update':
        return QasehIcons.ticket_curved;
      case 'promo':
      case 'marketing':
        return QasehIcons.discount_curved;
      case 'security':
        return QasehIcons.shield_done_curved;
      case 'kyc':
        return QasehIcons.profile_curved;
      default:
        return QasehIcons.notification_curved;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'payment':
      case 'payment_success':
        return AppColors.success;
      case 'sms':
      case 'sms_received':
        return AppColors.bluePrimary;
      case 'support':
      case 'ticket_update':
        return AppColors.warning;
      case 'promo':
      case 'marketing':
        return AppColors.info;
      case 'security':
        return AppColors.error;
      case 'kyc':
        return AppColors.primary;
      default:
        return AppColors.mutedStrong;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقائق';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعات';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              icon: Icon(QasehIcons.tick_square_curved, size: 18, color: AppColors.bluePrimary),
              label: Text(
                'تحديد الكل كمقروء',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.bluePrimary),
              ),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.notifications.isEmpty
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
                  child: state.notifications.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(icon: QasehIcons.notification_curved, message: 'لا توجد إشعارات'),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.notifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final notif = state.notifications[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: notif.isRead ? AppColors.canvasLight : AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: notif.isRead ? AppColors.hairlineLight : AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _colorForType(notif.type).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _iconForType(notif.type),
                                      size: 20,
                                      color: _colorForType(notif.type),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: AppTextStyles.labelMedium.copyWith(
                                                  color: AppColors.ink,
                                                  fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (!notif.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.bluePrimary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif.body,
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedStrong),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(notif.createdAt),
                                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
