import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).forgotPassword(_emailController.text.trim());
    final state = ref.read(authProvider);
    if (state.error == null && mounted) {
      setState(() => _submitted = true);
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
            child: _submitted ? _buildSuccessView() : _buildForm(authState),
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
            'نسيت كلمة المرور',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'البريد الإلكتروني',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                ),
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceStrongLight,
                  hintText: 'example@email.com',
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
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                  if (!v.contains('@')) return 'يرجى إدخال بريد إلكتروني صالح';
                  return null;
                },
              ),
            ],
          ),
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
            label: 'إرسال رابط إعادة التعيين',
            isLoading: authState.isLoading,
            isDisabled: authState.isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.push('/login'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'تذكرت كلمة المرور؟ تسجيل الدخول',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.bluePrimary),
            ),
          ),
        ],
      ),
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
          'تم إرسال الرابط',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'تحقق من بريدك الإلكتروني للعثور على رابط إعادة تعيين كلمة المرور',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppButton(
          variant: AppButtonVariant.large,
          label: 'العودة إلى تسجيل الدخول',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
