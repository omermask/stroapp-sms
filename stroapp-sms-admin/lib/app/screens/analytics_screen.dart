import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _verifications;
  Map<String, dynamic>? _carriers;
  List<dynamic> _targets = [];
  bool _loadingDash = true;
  bool _loadingVerifications = true;
  bool _loadingCarriers = true;
  bool _loadingTargets = true;

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
    await Future.wait([_fetchDashboard(), _fetchVerifications(), _fetchCarriers(), _fetchTargets()]);
  }

  Future<void> _fetchDashboard() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.analyticsDashboard);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) setState(() { _dashboard = resp.data as Map<String, dynamic>?; _loadingDash = false; });
    } catch (_) { if (mounted) setState(() => _loadingDash = false); }
  }

  Future<void> _fetchVerifications() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.analyticsVerifications);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) setState(() { _verifications = resp.data as Map<String, dynamic>?; _loadingVerifications = false; });
    } catch (_) { if (mounted) setState(() => _loadingVerifications = false); }
  }

  Future<void> _fetchCarriers() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.analyticsCarriers);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) setState(() { _carriers = resp.data as Map<String, dynamic>?; _loadingCarriers = false; });
    } catch (_) { if (mounted) setState(() => _loadingCarriers = false); }
  }

  Future<void> _fetchTargets() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.analyticsMonthlyTargets);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _targets = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []); _loadingTargets = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingTargets = false); }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('analytics')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: t('verifications')),
            Tab(text: t('carriers')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(onRefresh: _fetchAll, child: _buildOverviewTab()),
          RefreshIndicator(
            onRefresh: _fetchAll,
            child: _loadingVerifications
                ? ListView(padding: const EdgeInsets.all(16), children: [const Center(child: CircularProgressIndicator())])
                : _verifications != null
                    ? _buildDataCard('Verifications', _verifications!)
                    : ListView(padding: const EdgeInsets.all(16), children: [Center(child: Text(t('noData')))]),
          ),
          RefreshIndicator(
            onRefresh: _fetchAll,
            child: _loadingCarriers
                ? ListView(padding: const EdgeInsets.all(16), children: [const Center(child: CircularProgressIndicator())])
                : _carriers != null
                    ? _buildDataCard('Carriers', _carriers!)
                    : ListView(padding: const EdgeInsets.all(16), children: [Center(child: Text(t('noData')))]),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_loadingDash)
          const Center(child: CircularProgressIndicator())
        else if (_dashboard != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('dashboard'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._dashboard!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${e.value}')]),
                  )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(t('monthlyTargets'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_loadingTargets) const Center(child: CircularProgressIndicator())
        else ..._targets.map((t) {
          final tg = t as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text(tg['month'] ?? ''),
              subtitle: Text('Users: ${tg['target_new_users'] ?? ''} | Revenue: ${tg['target_revenue'] ?? ''}'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDataCard(String title, Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...data.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${e.value}')]),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
