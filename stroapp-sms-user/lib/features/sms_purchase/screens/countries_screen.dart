import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/country.dart';
import '../../../core/models/price_info.dart';
import '../../../core/api/endpoints/services_api.dart';
import '../../../core/api/endpoints/purchase_api.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/api/api_exceptions.dart';

class CountriesScreen extends ConsumerStatefulWidget {
  final String serviceName;
  final String? displayName;
  const CountriesScreen({super.key, required this.serviceName, this.displayName});

  @override
  ConsumerState<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends ConsumerState<CountriesScreen> {
  List<Country> _countries = [];
  final Map<String, PriceInfo> _prices = {};
  final Map<String, int> _availableCounts = {};
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCountries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    setState(() => _isLoading = true);
    try {
      final servicesApi = ref.read(servicesApiProvider);
      final data = await servicesApi.getServiceCountries(widget.serviceName);
      final countries = data.map((e) => Country.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _countries = countries;
        _isLoading = false;
      });
      _fetchPrices(countries);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الدول');
      });
    }
  }

  Future<void> _fetchPrices(List<Country> countries) async {
    if (countries.isEmpty) return;
    final purchaseApi = ref.read(purchaseApiProvider);
    try {
      final countryCodes = countries.map((c) => c.code).toList();
      final response = await purchaseApi.getBulkPrices(widget.serviceName, countryCodes);
      final prices = <String, PriceInfo>{};
      final available = <String, int>{};
      response.forEach((code, data) {
        if (data is Map<String, dynamic>) {
          prices[code as String] = PriceInfo(
            service: widget.serviceName,
            country: code as String,
            provider: data['provider'] as String?,
            price: (data['provider_cost'] as num?)?.toDouble(),
            priceWithMarkup: (data['final_price_usd'] as num?)?.toDouble(),
            costCoins: (data['cost_coins'] as num?)?.toInt(),
          );
          final count = (data['available_count'] as num?)?.toInt();
          if (count != null) available[code as String] = count;
        }
      });
      if (mounted) setState(() {
        _prices.clear();
        _prices.addAll(prices);
        _availableCounts.clear();
        _availableCounts.addAll(available);
        _countries.sort((a, b) {
          final aCount = _availableCounts[a.code] ?? 0;
          final bCount = _availableCounts[b.code] ?? 0;
          if (aCount > 0 && bCount == 0) return -1;
          if (aCount == 0 && bCount > 0) return 1;
          return 0;
        });
      });
    } catch (_) {}
  }

  List<Country> get _filteredCountries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _countries;
    return _countries.where((c) =>
      c.name.toLowerCase().contains(query) ||
      c.code.toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: Text(widget.displayName ?? widget.serviceName),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchCountries)
              : Column(
                  children: [
                    Container(
                      color: AppColors.canvasLight,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن دولة...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                          prefixIcon: Icon(QasehIcons.search_curved, size: 20, color: AppColors.mutedStrong),
                          filled: true,
                          fillColor: AppColors.surfaceStrongLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredCountries.isEmpty
                          ? EmptyState(icon: QasehIcons.location_curved, message: 'لا توجد دول متاحة')
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _fetchCountries,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredCountries.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final country = _filteredCountries[index];
                                  final price = _prices[country.code];
                                  final costCoins = price?.costCoins ?? country.platformPrice?.toInt() ?? 0;
                                  final displayName = widget.displayName;
                                  return GestureDetector(
                                    onTap: () => context.push(
                                      '/sms/${Uri.encodeComponent(widget.serviceName)}/countries/${country.code}/purchase?country_name=${Uri.encodeComponent(country.name)}&provider=${country.provider != null ? Uri.encodeComponent(country.provider!) : ''}&display_name=${displayName != null ? Uri.encodeComponent(displayName) : ''}',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.canvasLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.hairlineLight),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.hairlineLight),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _flagEmoji(country.code),
                                                style: const TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  country.name,
                                                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  country.provider ?? '',
                                                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                                ),
                                                if (_availableCounts[country.code] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      '${_availableCounts[country.code]} رقم متاح',
                                                      style: AppTextStyles.caption.copyWith(color: AppColors.success),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (price != null || costCoins > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$costCoins عملة',
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: AppColors.onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceStrongLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '...',
                                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.mutedStrong),
                                            ),
                                          ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            final displayName = widget.displayName ?? widget.serviceName;
                                            ref.read(settingsApiProvider).createPreset(
                                              '$displayName - ${country.name}',
                                              widget.serviceName,
                                              country.code,
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('تم الحفظ في القوالب', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onPrimary)),
                                                backgroundColor: AppColors.success,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Icon(QasehIcons.bookmark_curved, size: 18, color: AppColors.mutedStrong),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(QasehIcons.arrow_right_curved, size: 12, color: AppColors.mutedStrong),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  String _flagEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    final first = code.runes.first - 0x41 + 0x1F1E6;
    final second = code.runes.last - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }
}
