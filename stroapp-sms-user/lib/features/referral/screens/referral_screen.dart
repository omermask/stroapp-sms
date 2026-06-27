import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/referral_provider.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(referralProvider.notifier).fetchReferralCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        backgroundColor: AppColors.canvasLight,
        elevation: 0,
        centerTitle: true,
        title: Text('الإحالة', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrongLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(QasehIcons.arrow_right_curved, size: 20, color: AppColors.ink),
          ),
        ),
      ),
      body: state.isLoading && state.info == null
          ? const LoadingIndicator()
          : state.error != null && state.info == null
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(referralProvider.notifier).fetchReferralCode(),
                )
              : _buildContent(state),
    );
  }

  Widget _buildContent(ReferralState state) {
    final info = state.info;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(QasehIcons.ticket_star_curved, size: 48, color: AppColors.onPrimary),
                const SizedBox(height: 12),
                Text('كود الإحالة الخاص بك', style: AppTextStyles.titleSmall.copyWith(color: AppColors.onPrimary)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        info?.code ?? '------',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          if (info?.code != null) {
                            Clipboard.setData(ClipboardData(text: info!.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الكود')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(QasehIcons.document_curved, size: 20, color: AppColors.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    final url = info?.referralUrl ?? 'https://stroapp.com/register?ref=${info?.code ?? ''}';
                    Share.share(url);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(QasehIcons.send_curved, size: 18, color: AppColors.onPrimary),
                        const SizedBox(width: 8),
                        Text('مشاركة الكود', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: QasehIcons.two_user_curved,
                  label: 'عدد الإحالات',
                  value: '${info?.totalReferrals ?? 0}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: QasehIcons.wallet_curved,
                  label: 'العملات المكتسبة',
                  value: '${info?.totalRewardCoins ?? 0}',
                ),
              ),
            ],
          ),
          if (info?.referralUrl != null && info!.referralUrl!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.canvasLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رابط الإحالة', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          info.referralUrl!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: info.referralUrl!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ الرابط')),
                          );
                        },
                        child: const AppIcon(name: AppIcons.copy, size: 20, color: AppColors.bluePrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (info?.referrals != null && info!.referrals!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(QasehIcons.three_user_curved, size: 20, color: AppColors.ink),
                const SizedBox(width: 8),
                Text('قائمة الإحالات', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvasLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineLight),
              ),
              child: Column(
                children: info.referrals!.take(20).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final refItem = entry.value as Map<String, dynamic>;
                  return Column(
                    children: [
                      if (i > 0) Divider(height: 1, color: AppColors.hairlineLight),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceStrongLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(QasehIcons.profile_curved, size: 18, color: AppColors.muted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                refItem['name']?.toString() ?? refItem['email']?.toString() ?? 'مستخدم',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                              ),
                            ),
                            if (refItem['reward_coins'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${refItem['reward_coins']}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.numberLarge.copyWith(color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
        ],
      ),
    );
  }
}
