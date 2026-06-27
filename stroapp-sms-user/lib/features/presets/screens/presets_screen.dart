import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/api/endpoints/services_api.dart';
import '../../../core/api/api_exceptions.dart';
import '../providers/presets_provider.dart';

class PresetsScreen extends ConsumerStatefulWidget {
  const PresetsScreen({super.key});

  @override
  ConsumerState<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends ConsumerState<PresetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presetsProvider.notifier).fetchPresets();
    });
  }

  Future<void> _showCreateDialog() async {
    final servicesApi = ref.read(servicesApiProvider);
    final settingsApi = ref.read(settingsApiProvider);

    List<Map<String, dynamic>>? services;
    try {
      final data = await servicesApi.getServices(null, 10000, 0);
      services = data.cast<Map<String, dynamic>>();
    } catch (_) {}

    if (services == null || services.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الخدمات', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    String? selectedServiceName;
    String? selectedServiceDisplay;
    List<Map<String, dynamic>>? countries;

    final serviceController = ValueNotifier<String?>(null);
    final countryController = ValueNotifier<String?>(null);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.canvasLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('قالب جديد', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
          content: ValueListenableBuilder(
            valueListenable: serviceController,
            builder: (context, svc, _) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الخدمة', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceStrongLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedServiceName,
                              hint: Text('اختر الخدمة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                              dropdownColor: AppColors.canvasLight,
                              items: services!.map((svc) {
                                final name = svc['name'] as String? ?? '';
                                final display = svc['display_name'] as String? ?? name;
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text(display, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
                                );
                              }).toList(),
                              onChanged: (val) async {
                                setDialogState(() {
                                  selectedServiceName = val;
                                  selectedServiceDisplay = services!.firstWhere((s) => s['name'] == val)['display_name'] as String? ?? val;
                                  countries = null;
                                  countryController.value = null;
                                });
                                if (val != null) {
                                  try {
                                    final data = await servicesApi.getServiceCountries(val);
                                    setDialogState(() {
                                      countries = data.cast<Map<String, dynamic>>();
                                    });
                                  } catch (_) {}
                                }
                              },
                            ),
                          ),
                        ),
                        if (selectedServiceName != null) ...[
                          const SizedBox(height: 16),
                          Text('الدولة', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceStrongLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: countryController.value,
                                hint: Text('اختر الدولة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                dropdownColor: AppColors.canvasLight,
                                items: (countries ?? []).map((c) {
                                  final code = c['code'] as String? ?? '';
                                  final name = c['name'] as String? ?? code;
                                  return DropdownMenuItem(
                                    value: code,
                                    child: Text(name, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setDialogState(() {
                                    countryController.value = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            if (selectedServiceName == null || countryController.value == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('يرجى اختيار الخدمة والدولة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            final countryName = (countries ?? []).firstWhere(
                              (c) => c['code'] == countryController.value,
                              orElse: () => {'name': countryController.value},
                            )['name'] as String? ?? countryController.value!;
                            final autoName = '$selectedServiceDisplay - $countryName';
                            try {
                              await settingsApi.createPreset(autoName, selectedServiceName!, countryController.value!);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (mounted) ref.read(presetsProvider.notifier).fetchPresets();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(extractErrorMessage(e, fallback: 'حدث خطأ'), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('حفظ', style: AppTextStyles.button.copyWith(color: AppColors.onPrimary), textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceStrongLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('إلغاء', style: AppTextStyles.button.copyWith(color: AppColors.mutedStrong), textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presetsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        backgroundColor: AppColors.canvasLight,
        elevation: 0,
        centerTitle: true,
        title: Text('القوالب', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(QasehIcons.plus_curved, color: AppColors.onPrimary),
      ),
      body: state.isLoading && state.presets.isEmpty
          ? const LoadingIndicator()
          : state.error != null && state.presets.isEmpty
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(presetsProvider.notifier).fetchPresets(),
                )
              : state.presets.isEmpty
                  ? const EmptyState(icon: QasehIcons.bag_curved, message: 'لا توجد قوالب بعد')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(presetsProvider.notifier).fetchPresets(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: state.presets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final preset = state.presets[index];
                          return Dismissible(
                            key: ValueKey(preset['id'] ?? index),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => showDialog<bool>(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  backgroundColor: AppColors.canvasLight,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('حذف القالب', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
                                  content: Text('هل أنت متأكد من حذف هذا القالب؟', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.bodyLight)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: Text('إلغاء', style: AppTextStyles.labelMedium.copyWith(color: AppColors.mutedStrong)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: AppColors.onDark,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('حذف', style: AppTextStyles.button),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(QasehIcons.delete_curved, color: Colors.white, size: 24),
                            ),
                            onDismissed: (_) {
                              ref.read(presetsProvider.notifier).deletePreset(preset['id'].toString());
                            },
                            child: GestureDetector(
                              onTap: () => context.push(
                                '/sms/${Uri.encodeComponent(preset['service'] as String)}/countries/${preset['country'] as String}/purchase?country_name=${Uri.encodeComponent(preset['country'] as String)}',
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.hairlineLight),
                                ),
                                child: Row(
                                  children: [
                                    ServiceIcon(serviceName: preset['service'] as String? ?? '', size: 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            preset['name']?.toString() ?? '',
                                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(QasehIcons.bag_curved, size: 12, color: AppColors.mutedStrong),
                                              const SizedBox(width: 4),
                                              Text(
                                                preset['service']?.toString() ?? '',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(QasehIcons.location_curved, size: 12, color: AppColors.mutedStrong),
                                              const SizedBox(width: 4),
                                              Text(
                                                preset['country']?.toString() ?? '',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(QasehIcons.arrow_left_curved, size: 18, color: AppColors.mutedStrong),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
