import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/widgets/app_snackbar.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  Map<String, dynamic>? _status;
  List<dynamic> _logs = [];
  List<dynamic> _markupRules = [];
  Map<String, dynamic>? _orchestrator;
  bool _loadingStatus = true;
  bool _loadingLogs = true;
  bool _loadingRules = true;
  bool _loadingOrchestrator = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchStatus(),
      _fetchLogs(),
      _fetchMarkupRules(),
      _fetchOrchestrator(),
    ]);
  }

  Future<void> _fetchStatus() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.syncStatus);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        setState(() {
          _status = resp.data as Map<String, dynamic>?;
          _loadingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _fetchLogs() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.syncStatus, queryParameters: {'limit': 20});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final data = resp.data;
        setState(() {
          _logs = data is List ? data : (data is Map ? (data['items'] as List? ?? []) : []);
          _loadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _fetchMarkupRules() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.syncMarkupRules);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final data = resp.data;
        setState(() {
          _markupRules = data is List ? data : (data is Map ? (data['items'] as List? ?? []) : []);
          _loadingRules = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRules = false);
    }
  }

  Future<void> _fetchOrchestrator() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.syncOrchestrator);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        setState(() {
          _orchestrator = resp.data as Map<String, dynamic>?;
          _loadingOrchestrator = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrchestrator = false);
    }
  }

  Future<void> _triggerSync() async {
    try {
      final r = await ApiClient().postV4(ApiConstants.syncTrigger, data: {});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchLogs();
        _fetchStatus();
      }
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  Future<void> _toggleOrchestrator() async {
    final isRunning = _orchestrator?['running'] == true;
    try {
      final r = isRunning
          ? await ApiClient().postV4(ApiConstants.syncOrchestratorStop, data: {})
          : await ApiClient().postV4(ApiConstants.syncOrchestratorStart, data: {});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchOrchestrator();
      }
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('sync'))),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOrchestratorCard(),
            const SizedBox(height: 12),
            _buildTriggerCard(),
            const SizedBox(height: 12),
            _buildStatusCard(),
            const SizedBox(height: 12),
            _buildSectionHeader(t('markupRule')),
            ..._loadingRules
                ? [const Center(child: CircularProgressIndicator())]
                : _markupRules.map((r) => _buildMarkupRuleTile(r as Map<String, dynamic>)).toList(),
            const SizedBox(height: 12),
            _buildSectionHeader(t('logs')),
            ..._loadingLogs
                ? [const Center(child: CircularProgressIndicator())]
                : _logs.map((l) => _buildLogTile(l as Map<String, dynamic>)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOrchestratorCard() {
    return Card(
      child: ListTile(
        leading: Icon(
          _orchestrator?['running'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved,
          color: _orchestrator?['running'] == true ? Colors.green : Colors.grey,
        ),
        title: Text(t('orchestrator')),
        subtitle: Text(_loadingOrchestrator
            ? t('loading')
            : _orchestrator?['running'] == true
                ? '${t('running')} (${_orchestrator?['interval_seconds'] ?? '?'}s)'
                : t('stopped')),
        trailing: ElevatedButton(
          onPressed: _toggleOrchestrator,
          child: Text(_orchestrator?['running'] == true ? t('deactivate') : t('activate')),
        ),
      ),
    );
  }

  Widget _buildTriggerCard() {
    return Card(
      child: ListTile(
        leading: const Icon(QasehIcons.activityCurved, color: AppColors.vividBlue),
        title: Text(t('triggerSync')),
        subtitle: Text(t('run')),
        trailing: ElevatedButton.icon(
          onPressed: _triggerSync,
          icon: const Icon(QasehIcons.playCurved, size: 16),
          label: Text(t('run')),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_loadingStatus) return Card(child: ListTile(title: Text(t('loading'))));
    if (_status == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('status'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._status!.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(e.key), Text('${e.value}')],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkupRuleTile(Map<String, dynamic> rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        title: Text(rule['service'] ?? rule['id'] ?? ''),
        subtitle: Text('${rule['country_code'] ?? ''} | markup: ${rule['markup_multiplier'] ?? ''}'),
        trailing: Icon(
          rule['is_active'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved,
          color: rule['is_active'] == true ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        title: Text('${log['sync_type'] ?? ''} - ${log['status'] ?? ''}'),
        subtitle: Text('${log['started_at'] ?? ''} | ${log['duration_seconds'] ?? ''}s'),
        trailing: Text('${log['services_count'] ?? 0} svc'),
      ),
    );
  }
}
