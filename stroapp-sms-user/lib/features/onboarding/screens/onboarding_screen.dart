import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/onboarding_api.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).fetchOnboarding();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    final nextPage = _currentPage + 1;
    if (nextPage < _steps.length) {
      await ref.read(onboardingProvider.notifier).fetchOnboarding();
      await ref.read(onboardingApiProvider).updateOnboardingStep(nextPage);
      _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage = nextPage);
    }
  }

  void _skip() async {
    await ref.read(onboardingProvider.notifier).skipOnboarding();
    if (mounted) context.go('/home');
  }

  void _complete() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted && ref.read(onboardingProvider).completed) {
      context.go('/home');
    }
  }

  static const _steps = [
    _OnboardingStep(
      icon: QasehIcons.ticket_star_curved,
      title: 'مرحباً بك في سترو آب',
      description: 'منصة التحقق عبر الرسائل النصية الأسرع والأسهل. استقبل رموز التحقق من مئات الخدمات حول العالم.',
    ),
    _OnboardingStep(
      icon: QasehIcons.bag_curved,
      title: 'خدمات متعددة',
      description: 'ادعم أكثر من 100 خدمة مختلفة. احصل على أرقام وهمية لتفعيل حساباتك على تيليجرام، واتساب، سناب شات، والمزيد.',
    ),
    _OnboardingStep(
      icon: QasehIcons.shield_done_curved,
      title: 'الخصوصية والأمان',
      description: 'نحن نحمي بياناتك. لا نشارك معلوماتك مع أي طرف ثالث. يمكنك حذف بياناتك في أي وقت.',
    ),
    _OnboardingStep(
      icon: QasehIcons.star_curved,
      title: 'جاهز للانطلاق!',
      description: 'لديك الآن كل ما تحتاجه. ابدأ باستخدام سترو آب واستقبل رموز التحقق بسهولة.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    if (state.isLoading && !state.completed) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (state.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _steps.length - 1)
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: _skip,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('تخطي', style: AppTextStyles.labelMedium.copyWith(color: AppColors.bluePrimary)),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(step.icon, size: 56, color: AppColors.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          step.title,
                          style: AppTextStyles.displaySmall.copyWith(color: AppColors.ink),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.description,
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.bodyLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.hairlineLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : (_currentPage == _steps.length - 1 ? _complete : _nextStep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 30, height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                              ),
                            )
                          : Text(
                              _currentPage == _steps.length - 1 ? 'ابدأ الآن' : 'التالي',
                              style: AppTextStyles.button,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
