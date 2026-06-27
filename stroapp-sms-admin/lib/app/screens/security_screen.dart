import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

import '../../core/utils/qaseh_icons.dart';
import '../../core/widgets/app_snackbar.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _scans = [];
  List<dynamic> _backups = [];
  List<dynamic> _drTests = [];
  Map<String, dynamic>? _compliance;
  Map<String, dynamic>? _secrets;
  Map<String, dynamic>? _drStatus;
  bool _loadingScans = true;
  bool _loadingBackups = true;
  bool _loadingDrTests = true;

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
      _fetchScans(),
      _fetchBackups(),
      _fetchDrTests(),
      _fetchCompliance(),
      _fetchSecrets(),
      _fetchDrStatus(),
    ]);
  }

  Future<void> _fetchScans() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.securityScans);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _scans = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingScans = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingScans = false); }
  }

  Future<void> _fetchBackups() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.securityBackups);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _backups = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingBackups = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingBackups = false); }
  }

  Future<void> _fetchDrTests() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.securityDRTests);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _drTests = d is Map ? (d['items'] as List? ?? []) : (d is List ? d : []); _loadingDrTests = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingDrTests = false); }
  }

  Future<void> _fetchCompliance() async {
    try { final r = await ApiClient().getV4(ApiConstants.securityCompliance, queryParameters: {'start_date': '2026-01-01', 'end_date': '2026-12-31'}); final resp = ApiResponse.fromJson(r.data, null); if (resp.success && mounted) setState(() => _compliance = resp.data as Map<String, dynamic>?); } catch (_) {}
  }

  Future<void> _fetchSecrets() async {
    try { final r = await ApiClient().getV4(ApiConstants.securitySecretsCheck); final resp = ApiResponse.fromJson(r.data, null); if (resp.success && mounted) setState(() => _secrets = resp.data as Map<String, dynamic>?); } catch (_) {}
  }

  Future<void> _fetchDrStatus() async {
    try { final r = await ApiClient().getV4(ApiConstants.securityDRStatus); final resp = ApiResponse.fromJson(r.data, null); if (resp.success && mounted) setState(() => _drStatus = resp.data as Map<String, dynamic>?); } catch (_) {}
  }

  Future<void> _runScan() async {
    try { final r = await ApiClient().postV4(ApiConstants.securityScan, data: {'scan_type': 'quick'}); final resp = ApiResponse.fromJson(r.data, null); if (resp.success && mounted) { showSuccessSnack(context, t('actionSuccess')); _fetchScans(); } } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  Future<void> _createBackup() async {
    try { final r = await ApiClient().postV4(ApiConstants.securityBackup, data: {}); final resp = ApiResponse.fromJson(r.data, null); if (resp.success && mounted) { showSuccessSnack(context, t('actionSuccess')); _fetchBackups(); } } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  Future<void> _runDrTest() async {
    try { final r = await ApiClient().postV4(ApiConstants.securityDRTest, data: {}); final resp = ApiResponse.fromJson(r.data, null); if (resp.success && mounted) { showSuccessSnack(context, t('actionSuccess')); _fetchDrTests(); _fetchDrStatus(); } } catch (_) { if (mounted) showServerErrorSnack(context); }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('security')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('scan')),
            Tab(text: t('backup')),
            Tab(text: 'DR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(onRefresh: _fetchAll, child: _buildScanTab()),
          RefreshIndicator(onRefresh: _fetchAll, child: _buildBackupTab()),
          RefreshIndicator(onRefresh: _fetchAll, child: _buildDRTab()),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_secrets != null)
          Card(
            child: ListTile(
              leading: Icon(_secrets!['configured'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved,
                  color: _secrets!['configured'] == true ? Colors.green : Colors.red),
              title: Text(t('secrets')),
              subtitle: Text('Configured: ${_secrets!['configured']} | Working: ${_secrets!['working']}'),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: _runScan, icon: const Icon(QasehIcons.scanCurved), label: Text(t('scanNow'))),
        const SizedBox(height: 12),
        if (_loadingScans) const Center(child: CircularProgressIndicator())
        else ..._scans.map((s) {
          final scan = s as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text('${scan['scan_type'] ?? ''} — ${scan['status'] ?? ''}'),
              subtitle: Text(scan['created_at'] ?? ''),
            ),
          );
        }),
        if (_compliance != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('compliance'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ..._compliance!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)), Expanded(child: Text('${e.value}', overflow: TextOverflow.ellipsis))]),
                  )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBackupTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(onPressed: _createBackup, icon: const Icon(QasehIcons.documentCurved), label: Text(t('createBackup'))),
        const SizedBox(height: 12),
        if (_loadingBackups) const Center(child: CircularProgressIndicator())
        else ..._backups.map((b) {
          final backup = b as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text(backup['id']?.toString().substring(0, 8) ?? ''),
              subtitle: Text('${backup['notes'] ?? ''} | ${backup['created_at'] ?? ''}'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDRTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_drStatus != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('drStatus'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ..._drStatus!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)), Expanded(child: Text('${e.value}', overflow: TextOverflow.ellipsis))]),
                  )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: _runDrTest, icon: const Icon(QasehIcons.playCurved), label: Text(t('drTest'))),
        const SizedBox(height: 12),
        if (_loadingDrTests) const Center(child: CircularProgressIndicator())
        else ..._drTests.map((d) {
          final test = d as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text('${test['test_type'] ?? ''} — ${test['status'] ?? ''}'),
              subtitle: Text(test['created_at'] ?? ''),
            ),
          );
        }),
      ],
    );
  }
}
