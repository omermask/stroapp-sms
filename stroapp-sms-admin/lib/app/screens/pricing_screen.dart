import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

import '../../core/utils/qaseh_icons.dart';
import '../../core/widgets/app_snackbar.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _templates = [];
  List<dynamic> _assignments = [];
  List<dynamic> _promotions = [];
  bool _loadingTemplates = true;
  bool _loadingAssignments = true;
  bool _loadingPromotions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchTemplates(), _fetchAssignments(), _fetchPromotions()]);
  }

  Future<void> _fetchTemplates() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.pricingTemplates, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          _templates = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []);
          _loadingTemplates = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  Future<void> _fetchAssignments() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.pricingAssignments, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          _assignments = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []);
          _loadingAssignments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssignments = false);
    }
  }

  Future<void> _fetchPromotions() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.pricingPromotions, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          _promotions = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []);
          _loadingPromotions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPromotions = false);
    }
  }

  Future<void> _togglePromotion(String id) async {
    try {
      final r = await ApiClient().postV4(ApiConstants.pricingPromotionToggle(id), data: {});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchPromotions();
      }
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('pricing')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('template')),
            Tab(text: t('assignment')),
            Tab(text: t('promotion')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(_loadingTemplates, _templates, (item) {
            final tpl = item as Map<String, dynamic>;
            return ListTile(
              title: Text(tpl['name'] ?? ''),
              subtitle: Text('markup: ${tpl['markup_multiplier'] ?? ''} | ${tpl['region'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tpl['is_promo'] == true)
                    const Icon(QasehIcons.discountCurved, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Icon(
                    tpl['is_active'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved,
                    color: tpl['is_active'] == true ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            );
          }),
          _buildListView(_loadingAssignments, _assignments, (item) {
            final a = item as Map<String, dynamic>;
            final user = a['user'] as Map<String, dynamic>?;
            final template = a['template'] as Map<String, dynamic>?;
            return ListTile(
              title: Text(user?['email'] ?? a['user_id'] ?? ''),
              subtitle: Text('template: ${template?['name'] ?? a['template_id'] ?? ''}'),
            );
          }),
          _buildListView(_loadingPromotions, _promotions, (item) {
            final p = item as Map<String, dynamic>;
            return ListTile(
              title: Text('${p['service'] ?? ''} — ${p['discount_percentage'] ?? ''}% off'),
              subtitle: Text('${p['original_price'] ?? ''} → ${p['promotional_price'] ?? ''}'),
              trailing: IconButton(
                icon: Icon(
                  p['is_active'] == true                   ? Icons.toggle_on : Icons.toggle_off_outlined,
                  color: p['is_active'] == true ? Colors.green : Colors.grey,
                ),
                onPressed: () => _togglePromotion(p['id'] ?? ''),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListView(bool loading, List<dynamic> items, Widget Function(dynamic) itemBuilder) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return Center(child: Text(t('noData')));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: itemBuilder(items[i]),
        ),
      ),
    );
  }
}
