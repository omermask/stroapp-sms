import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/orders_provider.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('طلباتي'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(ordersProvider.notifier).fetchOrders(),
                )
              : state.orders.isEmpty
                  ? EmptyState(
                      icon: QasehIcons.bag_curved,
                      message: 'لا توجد طلبات بعد',
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(ordersProvider.notifier).fetchOrders(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          final isComplete = order.status == 'completed' || order.status == 'done';
                          final isPending = order.status == 'pending' || order.status == 'waiting';
                          final isCancelled = order.status == 'cancelled' || order.status == 'canceled';
                          final isRefunded = order.refunded == true;

                          Color statusColor;
                          String statusText;

                          if (isComplete) {
                            statusColor = AppColors.success;
                            statusText = 'مكتمل';
                          } else if (isPending) {
                            statusColor = AppColors.warning;
                            statusText = 'بانتظار';
                          } else if (isCancelled) {
                            statusColor = AppColors.error;
                            statusText = 'ملغي';
                          } else if (isRefunded) {
                            statusColor = AppColors.info;
                            statusText = 'مسترجع';
                          } else {
                            statusColor = AppColors.muted;
                            statusText = order.status;
                          }

                          return GestureDetector(
                            onTap: () => context.push('/orders/${order.id}'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.canvasLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.hairlineLight),
                              ),
                              child: Row(
                                children: [
                                  ServiceIcon(
                                    serviceName: order.serviceName ?? order.service,
                                    size: 48,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.serviceName ?? order.service,
                                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 3),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            order.phoneNumber,
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.mutedStrong,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: AppTextStyles.caption.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${order.costCoins} عملة',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.bodyLight),
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
