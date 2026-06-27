import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/theme/app_colors.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _client = ApiClient();
  List<dynamic> _items = [];
  bool _loading = true;
  String _filter = 'pending';

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await _client.getV4('/admin/kyc/$_filter');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final tr = AppLocalizations.of(context)!.t;

    return Scaffold(
      appBar: AppBar(title: Text(tr('kyc'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tabBtn('Pending', _filter == 'pending'),
                const SizedBox(width: 8),
                _tabBtn('All', _filter == 'all'),
              ],
            ),
          ),
          Expanded(child: _buildBody(isDark, textColor)),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() {
        _filter = label == 'All' ? 'all' : 'pending';
        _fetch();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.caribbeanGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.caribbeanGreen : AppColors.cyprus.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : AppColors.cyprus,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textColor) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.t('noKycEntries')));
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightBlue.withValues(alpha: 0.2),
                child: const Icon(QasehIcons.scanCurved, color: AppColors.oceanBlue, size: 18),
              ),
              title: Text(item['user_id'] ?? '', style: TextStyle(color: textColor)),
              subtitle: Text('Status: ${item['status'] ?? 'pending'}', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(QasehIcons.arrowRightCurved),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _KycDetailScreen(item: item)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KycDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const _KycDetailScreen({required this.item});

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
      appBar: AppBar(title: Text(t('kycDetail'))),
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
          if (item['status'] == 'pending')
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        final id = item['id'] ?? item['profile_id'] ?? '';
                        await client.postV4(ApiConstants.kycVerify(id), data: {});
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) showServerErrorSnack(context);
                      }
                    },
                    icon: const Icon(QasehIcons.tickSquareFilled, size: 18),
                    label: Text(t('verify')),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.statusGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        final id = item['id'] ?? item['profile_id'] ?? '';
                        await client.postV4(ApiConstants.kycReject(id), data: {});
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) showServerErrorSnack(context);
                      }
                    },
                    icon: const Icon(QasehIcons.closeSquareCurved, size: 18),
                    label: Text(t('reject')),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.statusRed),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
