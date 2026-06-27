import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).resetPassword(widget.token, _passwordController.text);
    final state = ref.read(authProvider);
    if (state.error == null && mounted) {
      setState(() => _success = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(QasehIcons.arrow_left_curved, size: 20, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _success ? _buildSuccessView() : _buildForm(authState),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text(
            'إعادة تعيين كلمة المرور',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل كلمة المرور الجديدة',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildPasswordField('كلمة المرور الجديدة', _passwordController, _obscurePassword, (v) {
            setState(() => _obscurePassword = v);
          }),
          const SizedBox(height: 16),
          _buildPasswordField('تأكيد كلمة المرور', _confirmController, _obscureConfirm, (v) {
            setState(() => _obscureConfirm = v);
          }),
          const SizedBox(height: 24),
          if (authState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                authState.error!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          AppButton(
            variant: AppButtonVariant.large,
            label: 'إعادة تعيين',
            isLoading: authState.isLoading,
            isDisabled: authState.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    ValueChanged<bool> onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceStrongLight,
            hintText: '••••••••',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.5), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.5), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => onToggle(!obscure),
                child: Icon(
                  obscure ? QasehIcons.hide_curved : QasehIcons.show_curved,
                  size: 24,
                  color: AppColors.bodyLight,
                ),
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
            if (v.length < 8) return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
            if (controller == _confirmController && v != _passwordController.text) {
              return 'كلمة المرور غير متطابقة';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(QasehIcons.tick_square_filled, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 32),
        Text(
          'تم إعادة تعيين كلمة المرور',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppButton(
          variant: AppButtonVariant.large,
          label: 'تسجيل الدخول',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
