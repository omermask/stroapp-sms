import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';

class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _applications = [];
  List<dynamic> _tiers = [];
  bool _loadingApps = true;
  bool _loadingTiers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchApplications(), _fetchTiers()]);
  }

  Future<void> _fetchApplications() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.affiliateApplications, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _applications = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingApps = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingApps = false); }
  }

  Future<void> _fetchTiers() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.affiliateTiers);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _tiers = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []); _loadingTiers = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingTiers = false); }
  }

  Future<void> _reviewApplication(String id, String status) async {
    try {
      final r = await ApiClient().postV4(ApiConstants.affiliateApplicationReview(id), data: {'status': status});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) { showSuccessSnack(context, t('actionSuccess')); _fetchApplications(); }
    } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('affiliate')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('application')),
            Tab(text: t('tier')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingApps
              ? const Center(child: CircularProgressIndicator())
              : _applications.isEmpty
                  ? Center(child: Text(t('noData')))
                  : RefreshIndicator(
                      onRefresh: _fetchApplications,
                      child: ListView.builder(
                        itemCount: _applications.length,
                        itemBuilder: (_, i) {
                          final app = _applications[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(app['user_id'] ?? ''),
                              subtitle: Text('Status: ${app['status'] ?? ''}'),
                              trailing: app['status'] == 'pending'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check, color: Colors.green),
                                          onPressed: () => _reviewApplication(app['id'] ?? '', 'approved'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => _reviewApplication(app['id'] ?? '', 'rejected'),
                                        ),
                                      ],
                                    )
                                  : Chip(label: Text('${app['status'] ?? ''}')),
                            ),
                          );
                        },
                      ),
                    ),
          _loadingTiers
              ? const Center(child: CircularProgressIndicator())
              : _tiers.isEmpty
                  ? Center(child: Text(t('noData')))
                  : RefreshIndicator(
                      onRefresh: _fetchTiers,
                      child: ListView.builder(
                        itemCount: _tiers.length,
                        itemBuilder: (_, i) {
                          final tier = _tiers[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(tier['name'] ?? ''),
                              subtitle: Text('Rate: ${tier['base_rate'] ?? ''} | Min: ${tier['min_volume_usd'] ?? ''}'),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
