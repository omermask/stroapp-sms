import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';

class TelegramScreen extends StatefulWidget {
  const TelegramScreen({super.key});

  @override
  State<TelegramScreen> createState() => _TelegramScreenState();
}

class _TelegramScreenState extends State<TelegramScreen> {
  List<dynamic> _connections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await ApiClient().getV4(ApiConstants.telegramConnections);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        final d = resp.data;
        setState(() {
          _connections = d is List ? d : (d is Map ? (d['items'] as List? ?? []) : []);
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
      appBar: AppBar(title: Text(t('telegram'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _connections.isEmpty
              ? Center(child: Text(t('noData')))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    itemCount: _connections.length,
                    itemBuilder: (_, i) {
                      final c = _connections[i] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text('${c['chat_id'] ?? c['user_id'] ?? ''}'),
                          subtitle: Text('${c['username'] ?? ''}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
