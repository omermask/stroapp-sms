import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/notifications_api.dart';

class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends ConsumerState<NotificationPrefsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _smsEnabled = true;
  bool _emailEnabled = true;
  bool _pushEnabled = true;
  bool _marketingEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPrefs());
  }

  Future<void> _fetchPrefs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(notificationsApiProvider);
      final prefs = await api.getPreferences();
      setState(() {
        _smsEnabled = prefs['sms_enabled'] as bool? ?? true;
        _emailEnabled = prefs['email_enabled'] as bool? ?? true;
        _pushEnabled = prefs['push_enabled'] as bool? ?? true;
        _marketingEnabled = prefs['marketing_enabled'] as bool? ?? false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final api = ref.read(notificationsApiProvider);
      await api.updatePreferences({
        'sms_enabled': _smsEnabled,
        'email_enabled': _emailEnabled,
        'push_enabled': _pushEnabled,
        'marketing_enabled': _marketingEnabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchPrefs)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.canvasLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.hairlineLight),
                      ),
                      child: Column(
                        children: [
                          _buildToggle(
                            icon: QasehIcons.message_curved,
                            title: 'الإشعارات عبر SMS',
                            subtitle: 'استلام إشعارات عبر الرسائل النصية',
                            value: _smsEnabled,
                            onChanged: (v) => setState(() => _smsEnabled = v),
                          ),
                          Divider(height: 1, color: AppColors.hairlineLight),
                          _buildToggle(
                            icon: QasehIcons.send_curved,
                            title: 'الإشعارات عبر البريد الإلكتروني',
                            subtitle: 'استلام إشعارات عبر البريد الإلكتروني',
                            value: _emailEnabled,
                            onChanged: (v) => setState(() => _emailEnabled = v),
                          ),
                          Divider(height: 1, color: AppColors.hairlineLight),
                          _buildToggle(
                            icon: QasehIcons.notification_curved,
                            title: 'الإشعارات المباشرة',
                            subtitle: 'استلام إشعارات فورية داخل التطبيق',
                            value: _pushEnabled,
                            onChanged: (v) => setState(() => _pushEnabled = v),
                          ),
                          Divider(height: 1, color: AppColors.hairlineLight),
                          _buildToggle(
                            icon: QasehIcons.discount_curved,
                            title: 'الإشعارات التسويقية',
                            subtitle: 'استلام عروض وتنبيهات تسويقية',
                            value: _marketingEnabled,
                            onChanged: (v) => setState(() => _marketingEnabled = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                ),
                              )
                            : Text('حفظ الإعدادات', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.hairlineLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
