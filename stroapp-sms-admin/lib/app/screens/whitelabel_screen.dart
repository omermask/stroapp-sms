import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

class WhitelabelScreen extends StatefulWidget {
  const WhitelabelScreen({super.key});

  @override
  State<WhitelabelScreen> createState() => _WhitelabelScreenState();
}

class _WhitelabelScreenState extends State<WhitelabelScreen> {
  List<dynamic> _domains = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.whitelabelDomains);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          _domains = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('whitelabel'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _domains.isEmpty
              ? Center(child: Text(t('noData')))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    itemCount: _domains.length,
                    itemBuilder: (_, i) {
                      final d = _domains[i] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(d['domain'] ?? ''),
                          subtitle: Text('${d['status'] ?? ''}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
