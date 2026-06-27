import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/service.dart';
import '../../../core/api/endpoints/services_api.dart';
import '../../../core/api/api_exceptions.dart';

const _topServices = [
  'telegram',
  'whatsapp',
  'google',
  'facebook',
  'instagram',
  'tiktok',
  'twitter',
  'discord',
  'snapchat',
  'uber',
  'amazon',
  'netflix',
  'linkedin',
  'microsoft',
  'apple',
  'paypal',
  'ebay',
  'spotify',
  'twitch',
  'pinterest',
  'reddit',
  'github',
  'signal',
  'viber',
  'line',
  'wechat',
  'steam',
  'yahoo',
  'tinder',
  'google/gmail',
  'google voice',
  'google play',
  'airbnb',
  'youtube',
  'xbox',
  'playstation',
  'dropbox',
  'skype',
  'kakao',
  'coinbase',
  'binance',
  'cashapp',
  '1688',
  'imo',
  'vkontakte',
  'odnoklassniki',
  'android',
  'slack',
  'medium',
  'gitlab',
  'docker',
  'chrome',
  'firefox',
  'opera',
  'safari',
  'linux',
  'windows',
];

class ServicesListScreen extends ConsumerStatefulWidget {
  const ServicesListScreen({super.key});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  List<Service> _allServices = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final servicesApi = ref.read(servicesApiProvider);
      final servicesData = await servicesApi.getServices(null, 2000, 0);
      final services = servicesData.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
      final categories = services.map((s) => s.category ?? 'عام').toSet().toList()..sort();
      _allServices = services;
      _allServices.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        int aRank = -1, bRank = -1;
        for (int i = 0; i < _topServices.length; i++) {
          if (aRank == -1 && aName.contains(_topServices[i])) aRank = i;
          if (bRank == -1 && bName.contains(_topServices[i])) bRank = i;
        }
        if (aRank == -1) aRank = _topServices.length;
        if (bRank == -1) bRank = _topServices.length;
        final diff = aRank.compareTo(bRank);
        if (diff != 0) return diff;
        return aName.compareTo(bName);
      });
      setState(() {
        _categories = ['الكل', ...categories];
        _selectedCategory = 'الكل';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الخدمات');
      });
    }
  }

  List<Service> get _filteredServices {
    if (_selectedCategory == null || _selectedCategory == 'الكل') return _allServices;
    return _allServices.where((s) => (s.category ?? 'عام') == _selectedCategory).toList();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الخدمات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchData)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchData,
                  child: CustomScrollView(
                    slivers: [
                      if (_categories.length > 1)
                        SliverToBoxAdapter(
                          child: Container(
                            color: AppColors.canvasLight,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _categories.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final selected = cat == _selectedCategory;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedCategory = cat),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: selected ? AppColors.primary : AppColors.surfaceStrongLight,
                                        border: Border.all(
                                          color: selected ? AppColors.primary : AppColors.hairlineLight,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        cat,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: selected ? AppColors.onPrimary : AppColors.bodyLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      if (_filteredServices.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: QasehIcons.bag_curved,
                            message: 'لا توجد خدمات متاحة',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final service = _filteredServices[index];
                                final name = service.displayName;
                                return GestureDetector(
                                  onTap: () => context.push('/sms/${Uri.encodeComponent(service.name)}/countries?display_name=${Uri.encodeComponent(service.displayName)}'),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.canvasLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.hairlineLight),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ServiceIcon(serviceName: name, size: 48),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.caption.copyWith(color: AppColors.ink),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _filteredServices.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
