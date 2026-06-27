import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

import '../../core/utils/qaseh_icons.dart';
import '../../core/widgets/app_snackbar.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _ips = [];
  List<dynamic> _tokens = [];
  bool _loadingIps = true;
  bool _loadingTokens = true;

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
    await Future.wait([_fetchIps(), _fetchTokens()]);
  }

  Future<void> _fetchIps() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.blacklistIps);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final data = resp.data;
        setState(() {
          _ips = data is List ? data : (data is Map ? (data['items'] as List? ?? []) : []);
          _loadingIps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIps = false);
    }
  }

  Future<void> _fetchTokens() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.blacklistTokens);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final data = resp.data;
        setState(() {
          _tokens = data is List ? data : (data is Map ? (data['items'] as List? ?? []) : []);
          _loadingTokens = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTokens = false);
    }
  }

  Future<void> _blockIp() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('block')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: t('ipAddress'), hintText: t('ipAddressHint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      final r = await ApiClient().postV4(ApiConstants.blockIp(), data: {'ip_address': result});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchIps();
      }
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  Future<void> _unblockIp(String ip) async {
    try {
      final r = await ApiClient().postV4(ApiConstants.unblockIp(), data: {'ip_address': ip});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchIps();
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
        title: Text(t('blacklist')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'IP ${t('address').toLowerCase()}'),
            Tab(text: t('token')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _blockIp,
            tooltip: t('block'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingIps
              ? const Center(child: CircularProgressIndicator())
              : _ips.isEmpty
                  ? Center(child: Text(t('noData')))
                  : RefreshIndicator(
                      onRefresh: _fetchIps,
                      child: ListView.builder(
                        itemCount: _ips.length,
                        itemBuilder: (_, i) {
                          final ip = _ips[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(ip['ip_address'] ?? ''),
                              subtitle: Text(ip['reason'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(QasehIcons.closeSquareCurved, color: Colors.red),
                                onPressed: () => _unblockIp(ip['ip_address'] ?? ''),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          _loadingTokens
              ? const Center(child: CircularProgressIndicator())
              : _tokens.isEmpty
                  ? Center(child: Text(t('noData')))
                  : RefreshIndicator(
                      onRefresh: _fetchTokens,
                      child: ListView.builder(
                        itemCount: _tokens.length,
                        itemBuilder: (_, i) {
                          final tok = _tokens[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(tok['jti'] ?? ''),
                              subtitle: Text('${tok['token_type'] ?? ''} - ${tok['reason'] ?? ''}'),
                              trailing: Text(tok['user_id'] ?? ''),
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
