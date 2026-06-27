import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/deep_link_service.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../services/apple_auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final refCode = ref.read(referralCodeProvider);
    await ref.read(authProvider.notifier).register(
      _emailController.text.trim(),
      _passwordController.text,
      _displayNameController.text.trim(),
      '',
      ref: refCode,
    );
    if (refCode != null) {
      ref.read(referralCodeProvider.notifier).state = null;
    }
    final state = ref.read(authProvider);
    if (state.isAuthenticated && mounted) {
      context.go('/home');
    }
  }

  Future<void> _registerWithGoogle() async {
    final idToken = await ref.read(googleAuthServiceProvider).signIn();
    if (idToken == null) return;
    final refCode = ref.read(referralCodeProvider);
    await ref.read(authProvider.notifier).loginWithGoogle(idToken, ref: refCode);
    if (refCode != null) {
      ref.read(referralCodeProvider.notifier).state = null;
    }
    final state = ref.read(authProvider);
    if (state.isAuthenticated && mounted) {
      context.go('/home');
    }
  }

  Future<void> _registerWithApple() async {
    final idToken = await ref.read(appleAuthServiceProvider).signIn();
    if (idToken == null) return;
    final refCode = ref.read(referralCodeProvider);
    await ref.read(authProvider.notifier).loginWithApple(idToken, ref: refCode);
    if (refCode != null) {
      ref.read(referralCodeProvider.notifier).state = null;
    }
    final state = ref.read(authProvider);
    if (state.isAuthenticated && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const AppLogo(size: 80),
                  const SizedBox(height: 32),
                  Text(
                    'إنشاء حساب',
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل معلوماتك لإنشاء حساب جديد',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
                  ),
                  const SizedBox(height: 32),
                  _buildDisplayNameField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildConfirmField(),
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
                    label: 'إنشاء حساب',
                    isLoading: authState.isLoading,
                    isDisabled: authState.isLoading,
                    onPressed: _register,
                  ),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildSocialButtons(),
                  const SizedBox(height: 32),
                  _buildLoginLink(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'الاسم',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
          ),
        ),
        TextFormField(
          controller: _displayNameController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          decoration: _inputDecoration('الاسم الكامل'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'يرجى إدخال الاسم';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
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
          decoration: _inputDecoration('example@email.com'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
            if (!v.contains('@')) return 'يرجى إدخال بريد إلكتروني صالح';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'كلمة المرور',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
          ),
        ),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          decoration: _inputDecoration('••••••••').copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? QasehIcons.hide_curved : QasehIcons.show_curved,
                  size: 24,
                  color: AppColors.bodyLight,
                ),
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
            if (v.length < 8) return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
            if (!RegExp(r'[a-z]').hasMatch(v)) return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
            if (!RegExp(r'[0-9]').hasMatch(v)) return 'يجب أن تحتوي على رقم واحد على الأقل';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'تأكيد كلمة المرور',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
          ),
        ),
        TextFormField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          decoration: _inputDecoration('••••••••').copyWith(
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm ? QasehIcons.hide_curved : QasehIcons.show_curved,
                  size: 24,
                  color: AppColors.bodyLight,
                ),
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
            if (v != _passwordController.text) return 'كلمة المرور غير متطابقة';
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceStrongLight,
      hintText: hint,
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
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.hairlineLight, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.hairlineLight, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        SizedBox(
          width: 335,
          height: 50,
          child: OutlinedButton(
            onPressed: _registerWithGoogle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -1)),
                const SizedBox(width: 8),
                Text('Google', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
              ],
            ),
          ),
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 335,
            height: 50,
            child: OutlinedButton(
              onPressed: _registerWithApple,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\uF8FF', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.ink)),
                  const SizedBox(width: 8),
                  Text('Apple', style: AppTextStyles.button.copyWith(color: AppColors.ink)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'تسجيل الدخول',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.bluePrimary),
          ),
        ),
      ],
    );
  }
}
