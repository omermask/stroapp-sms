import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';

class GdprConsentScreen extends ConsumerStatefulWidget {
  const GdprConsentScreen({super.key});

  @override
  ConsumerState<GdprConsentScreen> createState() => _GdprConsentScreenState();
}

class _GdprConsentScreenState extends ConsumerState<GdprConsentScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExporting = false;
  String? _error;
  bool _marketing = false;
  bool _analytics = false;
  bool _dataSharing = false;
  Map<String, dynamic>? _retentionPolicy;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final consent = await ref.read(settingsApiProvider).getGdprConsent();
      final retention = await ref.read(settingsApiProvider).getRetentionPolicy();
      if (mounted) {
        setState(() {
          _marketing = consent['marketing'] as bool? ?? false;
          _analytics = consent['analytics'] as bool? ?? false;
          _dataSharing = consent['data_sharing'] as bool? ?? false;
          _retentionPolicy = retention;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _saveConsent() async {
    setState(() { _isSaving = true; _error = null; });
    try {
      await ref.read(settingsApiProvider).updateGdprConsent(_marketing, _analytics, _dataSharing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إعدادات الخصوصية')),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  Future<void> _exportData() async {
    setState(() { _isExporting = true; _error = null; });
    try {
      final export = await ref.read(settingsApiProvider).getGdprExport();
      if (mounted) {
        final downloadUrl = export['url'] as String? ?? export['download_url'] as String?;
        if (downloadUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('رابط التحميل: $downloadUrl')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تجهيز تصدير البيانات، سيتم إرساله إلى بريدك الإلكتروني')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() { _isExporting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الخصوصية وحماية البيانات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(QasehIcons.danger_triangle_curved, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _fetchData, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                            Row(
                              children: [
                                Icon(QasehIcons.shield_done_curved, size: 22, color: AppColors.ink),
                                const SizedBox(width: 10),
                                Text('إعدادات الموافقة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildConsentToggle(
                              title: 'التسويق',
                              subtitle: 'الموافقة على استلام العروض التسويقية والإعلانات',
                              value: _marketing,
                              onChanged: (v) => setState(() { _marketing = v; }),
                            ),
                            const Divider(height: 1, color: AppColors.hairlineLight),
                            _buildConsentToggle(
                              title: 'التحليلات',
                              subtitle: 'الموافقة على جمع بيانات الاستخدام لتحسين الخدمة',
                              value: _analytics,
                              onChanged: (v) => setState(() { _analytics = v; }),
                            ),
                            const Divider(height: 1, color: AppColors.hairlineLight),
                            _buildConsentToggle(
                              title: 'مشاركة البيانات',
                              subtitle: 'الموافقة على مشاركة البيانات مع شركائنا الموثوقين',
                              value: _dataSharing,
                              onChanged: (v) => setState(() { _dataSharing = v; }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_retentionPolicy != null) ...[
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
                              Row(
                                children: [
                                  Icon(QasehIcons.time_circle_curved, size: 22, color: AppColors.ink),
                                  const SizedBox(width: 10),
                                  Text('سياسة الاحتفاظ بالبيانات', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _retentionPolicy!['description'] as String? ?? 'يتم الاحتفاظ ببياناتك لمدة ${_retentionPolicy!['days'] ?? '--'} يوماً',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                              ),
                              if (_retentionPolicy!.containsKey('days'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'مدة الاحتفاظ: ${_retentionPolicy!['days']} يوماً',
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _isExporting ? null : _exportData,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.bluePrimary,
                                  side: const BorderSide(color: AppColors.bluePrimary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isExporting
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bluePrimary))
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(QasehIcons.download_curved, size: 18, color: AppColors.bluePrimary),
                                          const SizedBox(width: 6),
                                          const Text('تصدير البيانات', style: AppTextStyles.button),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveConsent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                                    : const Text('حفظ', style: AppTextStyles.button),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConsentToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
