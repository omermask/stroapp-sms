import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/rental.dart';
import '../providers/rentals_provider.dart';

class RentalsListScreen extends ConsumerStatefulWidget {
  const RentalsListScreen({super.key});

  @override
  ConsumerState<RentalsListScreen> createState() => _RentalsListScreenState();
}

class _RentalsListScreenState extends ConsumerState<RentalsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rentalsProvider.notifier).fetchRentals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الإيجارات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/rentals/new'),
        backgroundColor: AppColors.primary,
        child: Icon(QasehIcons.plus_curved, color: AppColors.onPrimary),
      ),
    );
  }

  Widget _buildBody(RentalsState state) {
    if (state.isLoading && state.rentals.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.rentals.isEmpty) {
      return CustomErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(rentalsProvider.notifier).fetchRentals(),
      );
    }

    if (state.rentals.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(rentalsProvider.notifier).fetchRentals(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const EmptyState(
                icon: QasehIcons.bag_curved,
                message: 'لا توجد إيجارات بعد',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(rentalsProvider.notifier).fetchRentals(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.rentals.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final rental = state.rentals[index];
          return _buildRentalCard(rental);
        },
      ),
    );
  }

  Widget _buildRentalCard(Rental rental) {
    final statusColor = _statusColor(rental.status);
    final statusText = _statusText(rental.status);

    return GestureDetector(
      onTap: () => context.push('/rentals/${rental.id}'),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(QasehIcons.message_curved, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rental.service, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${rental.country} - ${rental.provider}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(rental.phoneNumber, style: AppTextStyles.numberMedium.copyWith(color: AppColors.ink)),
                const Spacer(),
                Icon(QasehIcons.wallet_curved, size: 14, color: AppColors.mutedStrong),
                const SizedBox(width: 4),
                Text('${rental.costCoins}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
              ],
            ),
            if (rental.expiresAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(QasehIcons.time_circle_curved, size: 14, color: AppColors.mutedStrong),
                  const SizedBox(width: 4),
                  Text(
                    'ينتهي: ${_formatDate(rental.expiresAt!)}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'نشط':
        return AppColors.success;
      case 'expired':
      case 'منتهي':
        return AppColors.mutedStrong;
      case 'cancelled':
      case 'ملغي':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشط';
      case 'expired':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
