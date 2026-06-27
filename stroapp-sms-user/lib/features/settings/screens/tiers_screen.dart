import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/models/tier.dart';

class TiersScreen extends ConsumerStatefulWidget {
  const TiersScreen({super.key});

  @override
  ConsumerState<TiersScreen> createState() => _TiersScreenState();
}

class _TiersScreenState extends ConsumerState<TiersScreen> {
  List<Tier> _tiers = [];
  Tier? _currentTier;
  bool _isLoading = true;
  bool _isUpgrading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final tiersData = await ref.read(settingsApiProvider).getTiers();
      final currentData = await ref.read(settingsApiProvider).getCurrentTier();
      if (mounted) {
        setState(() {
          _tiers = tiersData.map((e) => Tier.fromJson(e as Map<String, dynamic>)).toList();
          _currentTier = Tier.fromJson(currentData['config'] as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _upgradeTier(Tier tier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('ترقية المستوى', style: AppTextStyles.titleMedium),
        content: Text('هل أنت متأكد من الترقية إلى مستوى "${tier.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ترقية', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() { _isUpgrading = true; });
      try {
        await ref.read(settingsApiProvider).upgradeTier(tier.tier);
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت الترقية بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() { _isUpgrading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('المستويات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchData,
        child: _isLoading
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentTier != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(QasehIcons.star_curved, size: 24, color: AppColors.onPrimary),
                                    const SizedBox(width: 8),
                                    Text('المستوى الحالي', style: AppTextStyles.titleSmall.copyWith(color: AppColors.onPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _currentTier!.name,
                                  style: AppTextStyles.displaySmall.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                                ),
                                if (_currentTier!.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentTier!.description!,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          children: [
                            Icon(QasehIcons.category_curved, size: 18, color: AppColors.ink),
                            const SizedBox(width: 8),
                            Text('المستويات المتاحة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._tiers.map((tier) {
                          final isCurrent = _currentTier?.tier == tier.tier;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent ? AppColors.primary : AppColors.hairlineLight,
                                width: isCurrent ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(tier.name, style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('الحالي', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                        ),
                                    ],
                                  ),
                                  if (tier.priceMonthly != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${tier.priceMonthly!.toStringAsFixed(2)} / شهرياً',
                                      style: AppTextStyles.numberMedium.copyWith(color: AppColors.bluePrimary),
                                    ),
                                  ],
                                  if (tier.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(tier.description!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                  ],
                                  if (tier.features != null && tier.features!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    ...tier.features!.entries.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            e.value == true ? QasehIcons.tick_square_curved : QasehIcons.close_square_curved,
                                            size: 16,
                                            color: e.value == true ? AppColors.success : AppColors.mutedStrong,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(e.key, style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink)),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                  if (tier.hasApiAccess)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(QasehIcons.tick_square_curved, size: 16, color: AppColors.success),
                                          const SizedBox(width: 8),
                                          Text('دعم API', style: AppTextStyles.bodySmall.copyWith(color: AppColors.ink)),
                                        ],
                                      ),
                                    ),
                                  if (tier.quotaUsd != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'الحد الشهري: \$${tier.quotaUsd!.toStringAsFixed(2)}',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                      ),
                                    ),
                                  if (!isCurrent) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: _isUpgrading ? null : () => _upgradeTier(tier),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: tier.priceMonthly != null && tier.priceMonthly! > 0
                                              ? AppColors.primary
                                              : AppColors.success,
                                          foregroundColor: AppColors.onPrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: _isUpgrading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                                            : Text(
                                                tier.priceMonthly != null && tier.priceMonthly! > 0 ? 'ترقية' : 'تفعيل مجاني',
                                                style: AppTextStyles.button,
                                              ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }
}
