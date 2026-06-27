import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _logs = [];
  List<dynamic> _alerts = [];
  bool _loadingLogs = true;
  bool _loadingAlerts = true;
  bool _running = false;

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
    await Future.wait([_fetchLogs(), _fetchAlerts()]);
  }

  Future<void> _fetchLogs() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.reconciliationLogs, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _logs = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingLogs = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingLogs = false); }
  }

  Future<void> _fetchAlerts() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.reconciliationAlerts, queryParameters: {'per_page': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _alerts = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingAlerts = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingAlerts = false); }
  }

  Future<void> _runReconciliation() async {
    setState(() => _running = true);
    try {
      final r = await ApiClient().postV4(ApiConstants.reconciliationRun, data: {});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchAll();
      }
    } catch (_) { if (mounted) showServerErrorSnack(context); }
    finally { if (mounted) setState(() => _running = false); }
  }

  Future<void> _resolveAlert(String id) async {
    try {
      final r = await ApiClient().postV4(ApiConstants.reconciliationAlertResolve(id), data: {});
      if (ApiResponse.fromJson(r.data, null).success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchAlerts();
      }
    } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('reconciliation')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('logs')),
            Tab(text: t('alert')),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _running
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: _runReconciliation,
                    tooltip: t('run'),
                  ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_loadingLogs, _logs, (item) {
            final l = item as Map<String, dynamic>;
            return ListTile(
              title: Text('${l['type'] ?? ''} — ${l['status'] ?? ''}'),
              subtitle: Text(l['created_at'] ?? ''),
            );
          }),
          _buildList(_loadingAlerts, _alerts, (item) {
            final a = item as Map<String, dynamic>;
            return ListTile(
              title: Text('${a['severity'] ?? ''}: ${a['message'] ?? ''}'),
              subtitle: Text(a['created_at'] ?? ''),
              trailing: a['resolved'] == true
                  ? Chip(label: Text(t('resolved')), visualDensity: VisualDensity.compact)
                  : IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _resolveAlert(a['id'] ?? ''),
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
