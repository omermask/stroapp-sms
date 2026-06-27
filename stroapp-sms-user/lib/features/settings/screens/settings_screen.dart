import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.canvasLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(QasehIcons.profile_curved, size: 28, color: AppColors.onPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'مستخدم',
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('الحساب'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            context,
            icon: QasehIcons.profile_curved,
            title: 'الملف الشخصي',
            onTap: () => context.push('/settings/profile'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.password_curved,
            title: 'تغيير كلمة المرور',
            onTap: () => context.push('/settings/change-password'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.shield_done_curved,
            title: 'مفاتيح API',
            onTap: () => context.push('/settings/api-keys'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.lock_curved,
            title: 'التحقق الثنائي (MFA)',
            onTap: () => context.push('/settings/mfa'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.ticket_curved,
            title: 'الجلسات النشطة',
            onTap: () => context.push('/settings/sessions'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.send_curved,
            title: 'Webhooks',
            onTap: () => context.push('/settings/webhooks'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.ticket_star_curved,
            title: 'المستويات',
            onTap: () => context.push('/settings/tiers'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.call_curved,
            title: 'تحويل الرسائل',
            onTap: () => context.push('/settings/forwarding'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.shield_done_curved,
            title: 'الخصوصية (GDPR)',
            onTap: () => context.push('/settings/gdpr'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.danger_triangle_curved,
            title: 'حذف الحساب',
            onTap: () => context.push('/settings/delete-account'),
            iconColor: AppColors.error,
            textColor: AppColors.error,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('الخدمات'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            context,
            icon: QasehIcons.message_curved,
            title: 'الدعم الفني',
            onTap: () => context.push('/support'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.activity_curved,
            title: 'الإحالات',
            onTap: () => context.push('/referral'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.document_curved,
            title: 'البريد المؤقت',
            onTap: () => context.push('/temp-email'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.voice_curved,
            title: 'شراء صوت',
            onTap: () => context.push('/voice'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.chart_curved,
            title: 'التسويق بالعمولة',
            onTap: () => context.push('/affiliate'),
          ),
          _buildSettingsItem(
            context,
            icon: QasehIcons.shield_done_curved,
            title: 'التحقق (KYC)',
            onTap: () => context.push('/kyc/status'),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('التفضيلات'),
          const SizedBox(height: 8),
          _buildThemeToggle(ref),
          const SizedBox(height: 24),
          _buildSectionTitle('أخرى'),
          const SizedBox(height: 8),
          _buildSettingsItem(
            context,
            icon: QasehIcons.info_square_curved,
            title: 'حول التطبيق',
            onTap: () => _showAbout(context),
            showArrow: false,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تسجيل الخروج', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink));
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
    Color iconColor = AppColors.bodyLight,
    Color textColor = AppColors.ink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: AppColors.canvasLight,
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
              ),
              if (showArrow)
                Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.mutedStrong),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.canvasLight,
      child: Row(
        children: [
          Icon(
            settingsState.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
            size: 22,
            color: AppColors.bodyLight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('الوضع المظلم', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
          ),
          Switch(
            value: settingsState.isDarkMode,
            activeTrackColor: AppColors.primary,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleDarkMode(),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'StroApp',
      applicationVersion: '1.0.0',
      applicationLegalese: 'جميع الحقوق محفوظة © 2026',
    );
  }
}
