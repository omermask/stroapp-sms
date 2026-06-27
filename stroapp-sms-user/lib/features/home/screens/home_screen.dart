import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/rental.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/tier.dart';
import '../../rentals/providers/rentals_provider.dart';
import '../providers/home_dashboard_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeDashboardProvider.notifier).fetchDashboard();
      ref.read(rentalsProvider.notifier).fetchRentals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeDashboardProvider);
    final authState = ref.watch(authProvider);
    final rentalsState = ref.watch(rentalsProvider);
    final user = state.user ?? authState.user;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.canvasLight,
                onRefresh: () => ref.read(homeDashboardProvider.notifier).fetchDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(user, state.unreadNotifications, state.balance),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                  Icon(QasehIcons.danger_triangle_curved, size: 20, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      _buildRentalsSection(rentalsState),
                      _buildCurrentTier(state.currentTier, usedToday: state.usedToday),
                      _buildPresetsShortcut(),
                      _buildQuickServices(state.topServices),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(dynamic user, int unreadCount, dynamic balance) {
    final displayName = user?.displayName ?? 'مستخدم';
    final coins = balance?.coins ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بك',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(QasehIcons.wallet_filled, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '$coins',
                            style: AppTextStyles.numberMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceStrongLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(QasehIcons.notification_curved, size: 24, color: AppColors.ink),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(QasehIcons.bag_curved, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel, style: AppTextStyles.labelSmall.copyWith(color: AppColors.bluePrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(QasehIcons.arrow_left_curved, size: 12, color: AppColors.bluePrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsShortcut() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/presets'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(QasehIcons.bookmark_curved, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('القوالب', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('خدماتك المفضلة المحفوظة', style: AppTextStyles.caption.copyWith(color: AppColors.bodyLight)),
                    ],
                  ),
                ),
                Icon(QasehIcons.arrow_left_curved, size: 18, color: AppColors.mutedStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRentalsSection(RentalsState rentalsState) {
    final active = rentalsState.rentals.where((r) => r.status == 'active').toList();
    final display = active.length > 3 ? active.sublist(0, 3) : active;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إيجار رقم', 'عرض الكل', () => context.push('/rentals')),
          const Divider(height: 1, color: AppColors.hairlineLight, indent: 16, endIndent: 16),
          if (display.isEmpty)
            GestureDetector(
              onTap: () => context.push('/rentals/new'),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(QasehIcons.plus_curved, size: 22, color: AppColors.onPrimary),
                    const SizedBox(width: 10),
                    Text('بدء إيجار جديد', style: AppTextStyles.titleSmall.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(display.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < display.length - 1 ? 12 : 0),
                    child: _buildRentalCard(display[i]),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Rental rental) {
    final expiresText = rental.expiresAt != null
        ? '${rental.expiresAt!.day}/${rental.expiresAt!.month} ${rental.expiresAt!.hour}:${rental.expiresAt!.minute.toString().padLeft(2, '0')}'
        : '';
    return GestureDetector(
      onTap: () => context.push('/rentals/${rental.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoftLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairlineLight),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(QasehIcons.message_curved, size: 22, color: AppColors.success),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(rental.service, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('نشط', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rental.phoneNumber,
                    style: AppTextStyles.numberMedium.copyWith(color: AppColors.ink, fontSize: 15),
                    textDirection: TextDirection.ltr,
                  ),
                  if (expiresText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(QasehIcons.time_circle_curved, size: 12, color: AppColors.mutedStrong),
                        const SizedBox(width: 4),
                        Text('ينتهي $expiresText', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong, fontSize: 11)),
                        const Spacer(),
                        Icon(QasehIcons.wallet_curved, size: 12, color: AppColors.mutedStrong),
                        const SizedBox(width: 2),
                        Text('${rental.costCoins}', style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTier(Tier? currentTier, {int usedToday = 0}) {
    final tierName = currentTier?.name ?? 'Freemium';
    final dailyLimit = currentTier?.dailyVerificationLimit ?? 20;
    final used = usedToday;
    final progress = dailyLimit > 0 ? used / dailyLimit : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(QasehIcons.ticket_star_curved, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('الباقة الحالية', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tierName == 'Freemium' ? AppColors.mutedStrong.withValues(alpha: 0.1) : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tierName, style: AppTextStyles.labelSmall.copyWith(
                  color: tierName == 'Freemium' ? AppColors.mutedStrong : AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('الاستهلاك اليومي', style: AppTextStyles.caption.copyWith(color: AppColors.bodyLight)),
              const Spacer(),
              Text(
                '$used / $dailyLimit',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.hairlineLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices(List services) {
    if (services.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('خدمات سريعة', 'عرض الكل', () => context.push('/sms')),
          const Divider(height: 1, color: AppColors.hairlineLight, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildServiceCard(services[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final display = service.displayName.toString();
    return GestureDetector(
      onTap: () => context.push('/sms/${Uri.encodeComponent(service.name)}/countries?display_name=${Uri.encodeComponent(display)}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoftLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairlineLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ServiceIcon(serviceName: display, size: 36),
            const SizedBox(height: 6),
            SizedBox(
              width: 56,
              child: Text(
                display.length > 8 ? '${display.substring(0, 7)}…' : display,
                style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
