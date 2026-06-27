import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/mfa_verify_dialog.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/services/mfa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/api/endpoints/services_api.dart';

class ForwardingConfigScreen extends ConsumerStatefulWidget {
  const ForwardingConfigScreen({super.key});

  @override
  ConsumerState<ForwardingConfigScreen> createState() => _ForwardingConfigScreenState();
}

class _ForwardingConfigScreenState extends ConsumerState<ForwardingConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _error;

  bool _isActive = false;
  bool _emailEnabled = false;
  final _emailController = TextEditingController();
  bool _webhookEnabled = false;
  final _webhookUrlController = TextEditingController();
  final _webhookSecretController = TextEditingController();
  bool _forwardAll = true;
  List<String> _forwardServices = [];
  List<Map<String, dynamic>> _allServices = [];

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _webhookUrlController.dispose();
    _webhookSecretController.dispose();
    super.dispose();
  }

  Future<void> _fetchConfig() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final config = await ref.read(settingsApiProvider).getForwardingConfig();
      final servicesApi = ref.read(servicesApiProvider);
      List<Map<String, dynamic>> services = [];
      try {
        final data = await servicesApi.getServices(null, 10000, 0);
        services = data.cast<Map<String, dynamic>>();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isActive = config['is_active'] as bool? ?? false;
          _emailEnabled = config['email_enabled'] as bool? ?? false;
          _emailController.text = config['email_address'] as String? ?? '';
          _webhookEnabled = config['webhook_enabled'] as bool? ?? false;
          _webhookUrlController.text = config['webhook_url'] as String? ?? '';
          _webhookSecretController.text = config['webhook_secret'] as String? ?? '';
          _forwardAll = config['forward_all'] as bool? ?? true;
          _forwardServices = (config['forward_services'] as List<dynamic>?)?.cast<String>() ?? [];
          _allServices = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الإعدادات'); _isLoading = false; });
    }
  }

  Future<void> _saveConfig() async {
    setState(() { _isSaving = true; _error = null; });
    try {
      await ref.read(settingsApiProvider).updateForwardingConfig({
        'is_active': _isActive,
        'email_enabled': _emailEnabled,
        'email_address': _emailController.text.trim(),
        'webhook_enabled': _webhookEnabled,
        'webhook_url': _webhookUrlController.text.trim(),
        'webhook_secret': _webhookSecretController.text.trim(),
        'forward_all': _forwardAll,
        'forward_services': _forwardAll ? null : _forwardServices,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ إعدادات التحويل', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on MfaRequiredException {
      setState(() => _isSaving = false);
      if (!mounted) return;
      final token = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MfaVerifyDialog(),
      );
      if (token != null && mounted) {
        ref.read(mfaTokenProvider.notifier).state = token;
        await _saveConfig();
      }
    } catch (e) {
      if (mounted) setState(() { _error = extractErrorMessage(e, fallback: 'حدث خطأ في الحفظ'); });
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  Future<void> _testForwarding() async {
    setState(() { _isTesting = true; _error = null; });
    try {
      final result = await ref.read(settingsApiProvider).testForwarding();
      final channels = (result['enabled_channels'] as List<dynamic>?)?.join(', ') ?? '—';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الإرسال بنجاح — القنوات المفعلة: $channels', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractErrorMessage(e, fallback: 'فشل الاختبار'), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isTesting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('إعدادات التحويل'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActiveToggle(),
                  const SizedBox(height: 16),
                  _buildEmailSection(),
                  const SizedBox(height: 16),
                  _buildWebhookSection(),
                  const SizedBox(height: 16),
                  _buildForwardScope(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
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
          Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Row(
        children: [
          Icon(QasehIcons.send_curved, size: 22, color: _isActive ? AppColors.success : AppColors.mutedStrong),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تفعيل التحويل', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  'تحويل الرسائل المستلمة إلى بريد إلكتروني أو Webhook',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeTrackColor: AppColors.success,
            onChanged: (v) => setState(() { _isActive = v; }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    return _buildSection('البريد الإلكتروني', Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('إرسال إلى البريد الإلكتروني', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
            ),
            Switch(
              value: _emailEnabled,
              activeTrackColor: AppColors.success,
              onChanged: (v) => setState(() { _emailEnabled = v; }),
            ),
          ],
        ),
        if (_emailEnabled) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'أدخل البريد الإلكتروني',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
              filled: true,
              fillColor: AppColors.surfaceSoftLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          Text(
            'ملاحظة: الإيميل يرسل كإشعار داخل التطبيق حالياً (إيميل خارجي قيد التطوير)',
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong, fontSize: 11),
          ),
        ],
      ],
    ));
  }

  Widget _buildWebhookSection() {
    return _buildSection('Webhook', Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('إرسال إلى Webhook', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
            ),
            Switch(
              value: _webhookEnabled,
              activeTrackColor: AppColors.success,
              onChanged: (v) => setState(() { _webhookEnabled = v; }),
            ),
          ],
        ),
        if (_webhookEnabled) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _webhookUrlController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'https://example.com/webhook',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
              filled: true,
              fillColor: AppColors.surfaceSoftLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _webhookSecretController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Secret (اختياري)',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
              filled: true,
              fillColor: AppColors.surfaceSoftLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.hairlineLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            obscureText: true,
          ),
        ],
      ],
    ));
  }

  Widget _buildForwardScope() {
    return _buildSection('نطاق التحويل', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('تحويل جميع الخدمات', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
            ),
            Switch(
              value: _forwardAll,
              activeTrackColor: AppColors.success,
              onChanged: (v) => setState(() { _forwardAll = v; _forwardServices = []; }),
            ),
          ],
        ),
        if (!_forwardAll && _allServices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('اختر الخدمات:', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allServices.map((s) {
              final name = s['name'] as String? ?? '';
              final display = s['display_name'] as String? ?? name;
              final selected = _forwardServices.contains(name);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _forwardServices.remove(name);
                    } else {
                      _forwardServices.add(name);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceSoftLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.hairlineLight),
                  ),
                  child: Text(
                    display,
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? AppColors.primary : AppColors.ink,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ));
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isTesting ? null : _testForwarding,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.bluePrimary,
                side: const BorderSide(color: AppColors.bluePrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isTesting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bluePrimary))
                  : const Text('اختبار', style: AppTextStyles.button),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveConfig,
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
    );
  }
}
