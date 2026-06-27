import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/voice_provider.dart';

class VoicePurchaseScreen extends ConsumerStatefulWidget {
  const VoicePurchaseScreen({super.key});

  @override
  ConsumerState<VoicePurchaseScreen> createState() => _VoicePurchaseScreenState();
}

class _VoicePurchaseScreenState extends ConsumerState<VoicePurchaseScreen> {
  String? _selectedService;
  String? _selectedCountry;
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceProvider.notifier).fetchServices();
    });
  }

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    if (_selectedService == null || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الخدمة والدولة')),
      );
      return;
    }
    await ref.read(voiceProvider.notifier).purchase(_selectedService!, _selectedCountry!);
    final state = ref.read(voiceProvider);
    if (state.error == null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.canvasLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Icon(QasehIcons.tick_square_curved, size: 48, color: AppColors.success),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تم الشراء بنجاح', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 8),
                Text(
                  'تم شراء خدمة الصوت بنجاح',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('تم', style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        backgroundColor: AppColors.canvasLight,
        elevation: 0,
        centerTitle: true,
        title: Text('شراء صوت', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrongLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(QasehIcons.arrow_right_curved, size: 20, color: AppColors.ink),
          ),
        ),
      ),
      body: state.isLoading && state.services.isEmpty
          ? const LoadingIndicator()
          : state.error != null && state.services.isEmpty
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(voiceProvider.notifier).fetchServices(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اختر الخدمة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 12),
                      ...state.services.map((service) => _buildServiceCard(service)),
                      const SizedBox(height: 24),
                      Text('الدولة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _countryController,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.canvasLight,
                          hintText: 'أدخل اسم الدولة',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(QasehIcons.location_curved, size: 20, color: AppColors.mutedStrong),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onChanged: (v) => _selectedCountry = v.trim(),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
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
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _purchase,
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
                              : Text('شراء', style: AppTextStyles.button),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final name = service['name']?.toString() ?? 'خدمة';
    final price = service['price']?.toString() ?? service['cost']?.toString() ?? '';
    final currency = service['currency']?.toString() ?? '';
    final isSelected = _selectedService == (service['id']?.toString() ?? service['service']?.toString() ?? name);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedService = service['id']?.toString() ?? service['service']?.toString() ?? name;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.canvasLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.hairlineLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceStrongLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                QasehIcons.voice_curved,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                  if (price.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$price $currency',
                      style: AppTextStyles.numberSmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.mutedStrong,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
