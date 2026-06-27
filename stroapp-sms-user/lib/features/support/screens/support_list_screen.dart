import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/support_provider.dart';

class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportProvider.notifier).fetchTickets();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'مفتوحة':
        return AppColors.bluePrimary;
      case 'pending':
      case 'قيد الانتظار':
        return AppColors.warning;
      case 'answered':
      case 'تم الرد':
        return AppColors.info;
      case 'closed':
      case 'مغلقة':
        return AppColors.success;
      default:
        return AppColors.muted;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'pending':
        return 'قيد الانتظار';
      case 'answered':
        return 'تم الرد';
      case 'closed':
        return 'مغلقة';
      default:
        return status;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقائق';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعات';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الدعم الفني'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/support/create'),
        child: Icon(QasehIcons.plus_curved, color: AppColors.onPrimary),
      ),
      body: state.isLoading && state.tickets.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.tickets.isEmpty
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(supportProvider.notifier).fetchTickets(),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(supportProvider.notifier).fetchTickets(),
                  child: state.tickets.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(icon: QasehIcons.ticket_curved, message: 'لا توجد تذاكر'),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.tickets.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final ticket = state.tickets[index];
                            final status = (ticket['status'] as String?) ?? '';
                            final subject = (ticket['subject'] as String?) ?? '';
                            final category = (ticket['category'] as String?) ?? '';
                            final priority = (ticket['priority'] as String?) ?? '';
                            final createdAt = (ticket['created_at'] as String?) ?? '';

                            return GestureDetector(
                              onTap: () => context.push('/support/${ticket['id']}'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.hairlineLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(QasehIcons.ticket_light, size: 20, color: AppColors.bluePrimary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            subject,
                                            style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: AppTextStyles.caption.copyWith(
                                              color: _statusColor(status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.hairlineLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            category,
                                            style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                          ),
                                        ),
                                        if (priority == 'عالية' || priority == 'high' || priority == 'عاجلة' || priority == 'urgent') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              priority,
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text(
                                          _formatDate(createdAt),
                                          style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
