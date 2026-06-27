import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/mfa_verify_dialog.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/services/mfa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final current = _currentController.text.trim();
    final newPassword = _newController.text.trim();
    await _doChangePassword(current, newPassword);
  }

  Future<void> _doChangePassword(String current, String newPassword) async {
    setState(() => _error = null);
    ref.read(settingsProvider.notifier).clearError();
    try {
      await ref.read(settingsProvider.notifier).changePassword(current, newPassword);
      final state = ref.read(settingsProvider);
      if (state.error != null) {
        setState(() { _error = state.error; });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );
        context.pop();
      }
    } on MfaRequiredException {
      if (!mounted) return;
      final token = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MfaVerifyDialog(),
      );
      if (token != null && mounted) {
        ref.read(mfaTokenProvider.notifier).state = token;
        await _doChangePassword(current, newPassword);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('تغيير كلمة المرور'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                    Text('كلمة المرور الحالية', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentController,
                      obscureText: _obscureCurrent,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'أدخل كلمة المرور الحالية',
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
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.mutedStrong),
                          onPressed: () => setState(() { _obscureCurrent = !_obscureCurrent; }),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال كلمة المرور الحالية' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('كلمة المرور الجديدة', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newController,
                      obscureText: _obscureNew,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'أدخل كلمة مرور جديدة',
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
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.mutedStrong),
                          onPressed: () => setState(() { _obscureNew = !_obscureNew; }),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور الجديدة';
                        if (v.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('تأكيد كلمة المرور الجديدة', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'أعد إدخال كلمة المرور الجديدة',
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
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.mutedStrong),
                          onPressed: () => setState(() { _obscureConfirm = !_obscureConfirm; }),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                        if (v != _newController.text) return 'كلمة المرور غير متطابقة';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(QasehIcons.danger_triangle_curved, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: settingsState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: settingsState.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                      : const Text('تغيير كلمة المرور', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
