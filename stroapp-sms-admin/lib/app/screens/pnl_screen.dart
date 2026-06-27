import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';

class PnlScreen extends StatefulWidget {
  const PnlScreen({super.key});

  @override
  State<PnlScreen> createState() => _PnlScreenState();
}

class _PnlScreenState extends State<PnlScreen> {
  List<dynamic> _reports = [];
  bool _loading = true;
  bool _generating = false;
  final _startCtrl = TextEditingController(text: DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0]);
  final _endCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.pnlReports);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          _reports = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final r = await ApiClient().postV4(ApiConstants.pnlGenerate, data: {
        'period_start': _startCtrl.text,
        'period_end': _endCtrl.text,
      });
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, t('actionSuccess'));
        _fetchReports();
      }
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('pnl'))),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('generate'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _startCtrl,
                          decoration: InputDecoration(labelText: t('startDate'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _endCtrl,
                          decoration: InputDecoration(labelText: t('endDate'), border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add),
                    label: Text(t('generate')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(t('report'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_reports.isEmpty)
            Center(child: Text(t('noData')))
          else
            ..._reports.map((r) {
              final report = r as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  title: Text('${report['period_start'] ?? ''} → ${report['period_end'] ?? ''}'),
                  subtitle: Text('Revenue: ${report['total_revenue'] ?? 0} | Profit: ${report['net_profit'] ?? 0}'),
                ),
              );
            }),
        ],
      ),
      ),
    );
  }
}
