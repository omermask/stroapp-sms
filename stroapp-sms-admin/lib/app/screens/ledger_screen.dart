import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<dynamic> _history = [];
  Map<String, dynamic>? _balances;
  bool _loadingHistory = true;
  bool _loadingBalances = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchHistory(), _fetchBalances()]);
  }

  Future<void> _fetchHistory() async {
    try {
      final r = await ApiClient().getV4('${ApiConstants.ledger}/history', queryParameters: {'limit': 50});
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() { _history = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []); _loadingHistory = false; });
      }
    } catch (_) { if (mounted) setState(() => _loadingHistory = false); }
  }

  Future<void> _fetchBalances() async {
    try {
      final r = await ApiClient().getV4('${ApiConstants.ledger}/balances');
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          if (d is List) {
            _balances = {for (final b in d) (b is Map ? b['currency'] ?? '' : ''): (b is Map ? b['balance'] : null)};
          } else if (d is Map) {
            _balances = d as Map<String, dynamic>?;
          }
          _loadingBalances = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loadingBalances = false); }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('ledger'))),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_loadingBalances && _balances != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('balances'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ..._balances!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${e.value}')]),
                    )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(t('history'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loadingHistory) const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty) Center(child: Text(t('noData')))
          else ..._history.map((h) {
            final entry = h as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                title: Text('${entry['entry_type'] ?? ''} — ${entry['amount'] ?? ''} ${entry['currency'] ?? ''}'),
                subtitle: Text(entry['description'] ?? ''),
                trailing: Text(entry['created_at'] ?? ''),
              ),
            );
          }),
        ],
      ),
      ),
    );
  }
}
