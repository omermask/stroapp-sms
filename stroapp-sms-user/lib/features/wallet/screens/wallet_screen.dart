import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/balance_provider.dart';
import '../providers/transactions_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(balanceProvider.notifier).fetchBalance();
      ref.read(transactionsProvider.notifier).fetchTransactions(limit: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final txState = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('المحفظة'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(balanceProvider.notifier).fetchBalance();
          await ref.read(transactionsProvider.notifier).fetchTransactions(limit: 10);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBalanceCard(balanceState),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildTransactionsSection(txState),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BalanceState state) {
    final coins = state.balance?.coins ?? 0;
    final usdValue = state.balance?.coinsInUsd;
    final lifetime = state.balance?.lifetimeCoins;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(QasehIcons.wallet_filled, size: 24, color: AppColors.onPrimary),
              const SizedBox(width: 8),
              Text('المحفظة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.onPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/wallet/top-up'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(QasehIcons.plus_curved, size: 12, color: AppColors.onPrimary),
                      const SizedBox(width: 4),
                      Text('شحن', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: AppColors.onPrimary),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(coins),
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'عملة',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  usdValue != null ? '\$${usdValue.toStringAsFixed(2)} USD' : '—',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                ),
                if (lifetime != null) ...[
                  const SizedBox(width: 16),
                  Icon(QasehIcons.time_circle_curved, size: 14, color: AppColors.onPrimary.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    'إجمالي: ${_formatNumber(lifetime)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              icon: QasehIcons.plus_curved,
              label: 'شحن رصيد',
              color: AppColors.primary,
              onTap: () => context.push('/wallet/top-up'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionCard(
              icon: QasehIcons.document_curved,
              label: 'المعاملات',
              color: AppColors.info,
              onTap: () => context.push('/wallet/transactions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.canvasLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairlineLight),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(TransactionsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(QasehIcons.arrow_down_curved, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text('آخر المعاملات', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/wallet/transactions'),
                child: Row(
                  children: [
                    Text('عرض الكل', style: AppTextStyles.labelSmall.copyWith(color: AppColors.bluePrimary)),
                    const SizedBox(width: 4),
                    Icon(QasehIcons.arrow_right_curved, size: 12, color: AppColors.bluePrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: state.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : state.error != null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: AppColors.canvasLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.hairlineLight),
                      ),
                      child: Column(
                        children: [
                          Icon(QasehIcons.danger_triangle_curved, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(state.error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                        ],
                      ),
                    )
                  : state.transactions.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.hairlineLight),
                          ),
                          child: Column(
                            children: [
                              Icon(QasehIcons.wallet_curved, size: 48, color: AppColors.mutedStrong),
                              const SizedBox(height: 12),
                              Text('لا توجد معاملات بعد', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                            ],
                          ),
                        )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.canvasLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.hairlineLight),
                      ),
                      child: Column(
                        children: state.transactions.take(10).toList().asMap().entries.map((entry) {
                          final i = entry.key;
                          final tx = entry.value;
                          final isCredit = tx.amount > 0;
                          return Column(
                            children: [
                              if (i > 0) const Divider(height: 1, color: AppColors.hairlineLight),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: GestureDetector(
                          onTap: () => context.push('/wallet/transactions/${tx.id}', extra: tx),
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.type == 'deposit' ? 'إيداع عبر Google Pay' : tx.description ?? tx.type,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
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
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
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
