import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';


class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _revenue;
  List<dynamic> _costs = [];
  List<dynamic> _settlements = [];
  List<dynamic> _statements = [];
  List<dynamic> _taxConfigs = [];
  bool _loadingRevenue = true;
  bool _loadingCosts = true;
  bool _loadingSettlements = true;
  bool _loadingStatements = true;

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
    await Future.wait([
      _fetchRevenue(),
      _fetchCosts(),
      _fetchSettlements(),
      _fetchStatements(),
      _fetchTaxConfigs(),
    ]);
  }

  Future<void> _fetchRevenue() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.financialRevenue, queryParameters: {
        'start_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        'end_date': DateTime.now().toIso8601String().split('T')[0],
      });
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) setState(() { _revenue = resp.data as Map<String, dynamic>?; _loadingRevenue = false; });
    } catch (_) { if (mounted) setState(() => _loadingRevenue = false); }
  }

  Future<void> _fetchCosts() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.financialProviderCosts, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _costs = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingCosts = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingCosts = false); }
  }

  Future<void> _fetchSettlements() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.financialProviderSettlements, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _settlements = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingSettlements = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingSettlements = false); }
  }

  Future<void> _fetchStatements() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.financialStatements, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _statements = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingStatements = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingStatements = false); }
  }

  Future<void> _fetchTaxConfigs() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.financialTaxConfigs);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _taxConfigs = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []); });
      }
    } catch (_) {}
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('financial')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('revenue')),
            Tab(text: t('cost')),
            Tab(text: t('settlement')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRevenueTab(),
          _buildList(_loadingCosts, _costs, (item) {
            final c = item as Map<String, dynamic>;
            return ListTile(
              title: Text(c['provider_name'] ?? ''),
              subtitle: Text('Cost: ${c['total_cost'] ?? c['cost_per_unit'] ?? ''} | ${c['cost_date'] ?? ''}'),
            );
          }),
          _buildList(_loadingSettlements, _settlements, (item) {
            final s = item as Map<String, dynamic>;
            return ListTile(
              title: Text(s['provider_name'] ?? ''),
              subtitle: Text('Gross: ${s['gross_amount'] ?? ''} | Net: ${s['net_amount'] ?? ''}'),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_loadingRevenue)
          const Center(child: CircularProgressIndicator())
        else if (_revenue != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('revenue'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._revenue!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${e.value}')]),
                  )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_taxConfigs.isNotEmpty) ...[
          Text(t('tax'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ..._taxConfigs.map((t) {
            final tx = t as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                title: Text(tx['jurisdiction'] ?? ''),
                subtitle: Text('Rate: ${tx['tax_rate'] ?? ''}'),
                trailing: Icon(
                  tx['is_active'] == true ? Icons.check_circle : Icons.cancel,
                  color: tx['is_active'] == true ? Colors.green : Colors.grey,
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        if (_loadingStatements) const Center(child: CircularProgressIndicator())
        else ..._statements.map((s) {
          final stmt = s as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text('${stmt['period'] ?? ''}'),
              subtitle: Text('Amount: ${stmt['amount'] ?? ''}'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildList(bool loading, List<dynamic> items, Widget Function(dynamic) builder) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return Center(child: Text(t('noData')));
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: builder(items[i]),
        ),
      ),
    );
  }
}
