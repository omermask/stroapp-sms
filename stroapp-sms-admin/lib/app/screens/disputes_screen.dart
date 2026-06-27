import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/theme/app_colors.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final _client = ApiClient();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await _client.getV4('/admin/disputes/all');
      final apiResp = ApiResponse.fromJson(response.data, null);
      if (apiResp.success && apiResp.data != null) {
        final data = apiResp.data;
        if (mounted) {
          setState(() {
            _items = data is List ? data : (data['items'] as List? ?? []);
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        showServerErrorSnack(context);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(title: Text(t('disputes'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(t('noData')))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.statusOrange.withValues(alpha: 0.2),
                            child: const Icon(QasehIcons.dangerTriangleCurved, color: AppColors.statusOrange, size: 18),
                          ),
                          title: Text(item['subject'] ?? item['id'] ?? '', style: TextStyle(color: textColor)),
                          subtitle: Text('Status: ${item['status'] ?? 'open'} · ${item['category'] ?? ''}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(QasehIcons.arrowRightCurved),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _DisputeDetailScreen(item: item),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _DisputeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const _DisputeDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final client = ApiClient();

    Widget row(String label, String val) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: secondaryColor, fontSize: 13))),
          Expanded(child: Text(val, style: TextStyle(color: textColor, fontSize: 13))),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('disputeDetail'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...item.entries.map((e) => row(e.key, '${e.value}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (item['status'] == 'open')
            FilledButton.icon(
              onPressed: () async {
                try {
                  final id = item['id'] ?? '';
                  await client.postV4(ApiConstants.disputeResolve(id), data: {});
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {
                  if (context.mounted) showServerErrorSnack(context);
                }
              },
              icon: const Icon(QasehIcons.tickSquareFilled, size: 18),
              label: Text(t('resolveDispute')),
              style: FilledButton.styleFrom(backgroundColor: AppColors.statusGreen),
            ),
        ],
      ),
    );
  }
}
