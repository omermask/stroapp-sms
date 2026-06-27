import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

import '../../core/widgets/app_snackbar.dart';

class ResellerScreen extends StatefulWidget {
  const ResellerScreen({super.key});

  @override
  State<ResellerScreen> createState() => _ResellerScreenState();
}

class _ResellerScreenState extends State<ResellerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _accounts = [];
  List<dynamic> _subAccounts = [];
  bool _loadingAccs = true;
  bool _loadingSubs = true;

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
    await Future.wait([_fetchAccounts(), _fetchSubAccounts()]);
  }

  Future<void> _fetchAccounts() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.resellerAccounts, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _accounts = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingAccs = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingAccs = false); }
  }

  Future<void> _fetchSubAccounts() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.resellerSubAccounts, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _subAccounts = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingSubs = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingSubs = false); }
  }

  Future<void> _toggleAccount(String id) async {
    try {
      final r = await ApiClient().postV4(ApiConstants.resellerAccountToggle(id), data: {});
      if (ApiResponse.fromJson(r.data, null).success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchAccounts();
      }
    } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  Future<void> _toggleSubAccount(String id) async {
    try {
      final r = await ApiClient().postV4(ApiConstants.resellerSubAccountToggle(id), data: {});
      if (ApiResponse.fromJson(r.data, null).success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchSubAccounts();
      }
    } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('reseller')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('account')),
            Tab(text: t('subAccount')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_loadingAccs, _accounts, (item) {
            final a = item as Map<String, dynamic>;
            return ListTile(
              title: Text(a['user_id'] ?? a['id'] ?? ''),
              subtitle: Text('Credit: ${a['credit_limit'] ?? ''} | Markup: ${a['custom_markup'] ?? ''}'),
              trailing: IconButton(
                icon: Icon(
                  a['is_active'] == true ? Icons.toggle_on : Icons.toggle_off_outlined,
                  color: a['is_active'] == true ? Colors.green : Colors.grey,
                ),
                onPressed: () => _toggleAccount(a['id'] ?? ''),
              ),
            );
          }),
          _buildList(_loadingSubs, _subAccounts, (item) {
            final s = item as Map<String, dynamic>;
            return ListTile(
              title: Text(s['name'] ?? s['email'] ?? ''),
              subtitle: Text('Rate: ${s['rate_multiplier'] ?? ''} | Coins: ${s['coins'] ?? ''}'),
              trailing: IconButton(
                icon: Icon(
                  s['is_active'] == true ? Icons.toggle_on : Icons.toggle_off_outlined,
                  color: s['is_active'] == true ? Colors.green : Colors.grey,
                ),
                onPressed: () => _toggleSubAccount(s['id'] ?? ''),
              ),
            );
          }),
        ],
      ),
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
