import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsProvider.notifier).fetchTransactions(limit: 50);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('المعاملات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(transactionsProvider.notifier).fetchTransactions(limit: 50),
                )
              : state.transactions.isEmpty
                  ? EmptyState(icon: QasehIcons.wallet_curved, message: 'لا توجد معاملات')
                  : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(transactionsProvider.notifier).fetchTransactions(limit: 50),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      final isCredit = tx.amount > 0;
                      return GestureDetector(
                        onTap: () => context.push('/wallet/transactions/${tx.id}', extra: tx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          color: AppColors.canvasLight,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.canvasLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.hairlineLight),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    'https://developers.google.com/static/pay/api/images/brand-guidelines/google-pay-mark.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      isCredit ? QasehIcons.arrow_down_curved : QasehIcons.arrow_up_curved,
                                      size: 20,
                                      color: isCredit ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.type == 'deposit' ? 'إيداع عبر Google Pay' : tx.description ?? tx.type,
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDateTime(tx.createdAt),
                                      style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : ''}${tx.amount}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Icon(QasehIcons.arrow_left_curved, size: 14, color: AppColors.mutedStrong),
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

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقائق';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعات';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
