import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/app_snackbar.dart';
import '../screens/kyc_screen.dart';
import '../screens/disputes_screen.dart';
import '../screens/sync_screen.dart';
import '../screens/blacklist_screen.dart';
import '../screens/broadcast_screen.dart';
import '../screens/pricing_screen.dart';
import '../screens/pnl_screen.dart';
import '../screens/whitelabel_screen.dart';
import '../screens/telegram_screen.dart';
import '../screens/export_screen.dart';
import '../screens/security_screen.dart';
import '../screens/affiliate_screen.dart';
import '../screens/reseller_screen.dart';
import '../screens/financial_screen.dart';
import '../screens/reconciliation_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/ledger_screen.dart';
import 'tab_tickets.dart';

class TabSettings extends StatelessWidget {
  const TabSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(t('settings'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(label: t('systemSection')),
            _SettingsTile(icon: QasehIcons.settingCurved, label: t('status'), onTap: () => _openSettings(context)),
            _SettingsTile(icon: QasehIcons.workCurved, label: t('providers'), onTap: () => _openListPage(context, 'providers', ApiConstants.providers, (i) => '${i['display_name'] ?? i['name'] ?? ''}', sub: (i) => '${t('balance')}: ${i['balance'] ?? 'N/A'}', trail: (i) => Icon(i['enabled'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved, color: i['enabled'] == true ? Colors.green : Colors.grey), onTapTrail: (item) async { final name = item['name'] ?? ''; if (name.isEmpty) return; final enable = item['enabled'] != true; final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog( title: Text(enable ? t('enableProvider') : t('disableProvider')), content: Text('${enable ? t('enable') : t('disable')} "$name"?' ), actions: [ TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(enable ? t('enable') : t('disable'))), ], )); if (confirmed != true) return; await ApiClient().post(ApiConstants.providerToggle(name)); }),),
            _SettingsTile(icon: QasehIcons.workCurved, label: t('services'), onTap: () => _openListPage(context, 'services', ApiConstants.services, (i) => '${i['display_name'] ?? i['name'] ?? ''}', sub: (i) => '${i['category'] ?? ''}', trail: (i) => Icon(i['is_active'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved, color: i['is_active'] == true ? Colors.green : Colors.red), onTapTrail: (item) async { final name = item['name'] ?? ''; if (name.isEmpty) return; final enable = item['is_active'] != true; final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog( title: Text(enable ? t('enableService') : t('disableService')), content: Text('${enable ? t('enable') : t('disable')} "$name"?' ), actions: [ TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(enable ? t('enable') : t('disable'))), ], )); if (confirmed != true) return; await ApiClient().post(ApiConstants.serviceToggle(name)); }),),
            _SettingsTile(icon: QasehIcons.bookmarkCurved, label: t('featureFlags'), onTap: () => _openListPage(context, 'featureFlags', ApiConstants.featureFlags, (i) => '${i['name'] ?? ''}', sub: (i) => '${t('enabledLabel')}: ${i['enabled']}', trail: (i) => Icon(i['enabled'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved, color: i['enabled'] == true ? Colors.green : Colors.red))),
            _SettingsTile(icon: QasehIcons.paperCurved, label: t('tiers'), onTap: () => _openListPage(context, 'tiers', ApiConstants.tiers, (i) => '${i['name'] ?? ''}', sub: (i) => '${i['description'] ?? ''}')),
            const Divider(),
            _SectionHeader(label: t('usersSection')),
            _SettingsTile(icon: QasehIcons.messageCurved, label: t('emailTemplates'), onTap: () => _openListPage(context, 'emailTemplates', ApiConstants.emailTemplates, (i) => '${i['name'] ?? ''}', sub: (i) => '${i['subject'] ?? ''}', trail: (i) => Icon(i['is_active'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved, color: i['is_active'] == true ? Colors.green : Colors.red))),
            _SettingsTile(icon: QasehIcons.scanCurved, label: t('sessions'), onTap: () => _openListPage(context, 'sessions', ApiConstants.sessions, (i) => i['ip_address'] ?? '', sub: (i) => i['is_active'] == true ? t('active') : t('inactive'), trail: (i) => Icon(i['is_active'] == true ? QasehIcons.tickSquareFilled : QasehIcons.closeSquareCurved, color: i['is_active'] == true ? Colors.green : Colors.grey, size: 12))),
            _SettingsTile(icon: QasehIcons.documentCurved, label: t('waitlist'), onTap: () => _openListPage(context, 'waitlist', ApiConstants.waitlist, (i) => '${i['email'] ?? ''}', sub: (i) => '${i['name'] ?? ''}', trail: (i) => i['is_notified'] == true ? const Icon(QasehIcons.tickSquareCurved, color: Colors.green) : const Icon(QasehIcons.timeCircleCurved, color: Colors.orange))),
            _SettingsTile(icon: QasehIcons.notificationCurved, label: t('notifications'), onTap: () => _openListPage(context, 'notifications', ApiConstants.notifications, (i) => '${i['title'] ?? ''}', sub: (i) => '${i['type'] ?? i['notification_type'] ?? ''}')),
            const Divider(),
            _SectionHeader(label: t('verificationSection')),
            _SettingsTile(icon: QasehIcons.ticketCurved, label: t('supportTickets'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TabTickets())),),
            _SettingsTile(icon: QasehIcons.scanCurved, label: t('kyc'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycScreen()))),
            _SettingsTile(icon: QasehIcons.dangerTriangleCurved, label: t('disputes'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DisputesScreen()))),
            const Divider(),
            _SectionHeader(label: t('operationsSection')),
            _SettingsTile(icon: QasehIcons.activityCurved, label: t('sync'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SyncScreen()))),
            _SettingsTile(icon: QasehIcons.playCurved, label: t('broadcast'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BroadcastScreen()))),
            _SettingsTile(icon: QasehIcons.discountCurved, label: t('pricing'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PricingScreen()))),
            _SettingsTile(icon: QasehIcons.closeSquareCurved, label: t('blacklist'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlacklistScreen()))),
            _SettingsTile(icon: QasehIcons.documentCurved, label: t('whitelabel'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhitelabelScreen()))),
            const Divider(),
            _SectionHeader(label: t('businessSection')),
            _SettingsTile(icon: QasehIcons.twoUserCurved, label: t('affiliate'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AffiliateScreen()))),
            _SettingsTile(icon: QasehIcons.twoUserCurved, label: t('reseller'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResellerScreen()))),
            _SettingsTile(icon: QasehIcons.walletCurved, label: t('financial'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinancialScreen()))),
            _SettingsTile(icon: QasehIcons.chartCurved, label: t('pnl'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PnlScreen()))),
            _SettingsTile(icon: QasehIcons.chartCurved, label: t('analytics'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
            _SettingsTile(icon: QasehIcons.documentCurved, label: t('ledger'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LedgerScreen()))),
            _SettingsTile(icon: QasehIcons.settingCurved, label: t('reconciliation'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReconciliationScreen()))),
            const Divider(),
            _SectionHeader(label: t('securitySection')),
            _SettingsTile(icon: QasehIcons.lockCurved, label: t('security'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityScreen()))),
            _SettingsTile(icon: QasehIcons.messageCurved, label: t('telegram'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TelegramScreen()))),
            _SettingsTile(icon: QasehIcons.downloadCurved, label: t('exportData'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExportScreen()))),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext c) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const _AppSettingsPage()));
  void _openListPage(BuildContext c, String key, String endpoint, String Function(Map<String, dynamic>) title, {String? Function(Map<String, dynamic>)? sub, Widget? Function(Map<String, dynamic>)? trail, Future<void> Function(Map<String, dynamic>)? onTapTrail}) {
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => _ListPage(titleKey: key, endpoint: endpoint, itemTitle: title, itemSubtitle: sub, itemTrailing: trail, onTrailingTap: onTapTrail)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.vividBlue, letterSpacing: 0.5)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: AppColors.lightBlue.withValues(alpha: 0.2),
          radius: 16,
          child: Icon(icon, color: AppColors.vividBlue, size: 18),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(QasehIcons.arrowRightCurved, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _ListPage extends StatefulWidget {
  final String titleKey;
  final String endpoint;
  final String Function(Map<String, dynamic> item) itemTitle;
  final String? Function(Map<String, dynamic> item)? itemSubtitle;
  final Widget? Function(Map<String, dynamic> item)? itemTrailing;
  final Future<void> Function(Map<String, dynamic> item)? onTrailingTap;

  _ListPage({required this.titleKey, required this.endpoint, required this.itemTitle, this.itemSubtitle, this.itemTrailing, this.onTrailingTap});

  @override
  State<_ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<_ListPage> {
  List<dynamic> _items = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _filter(String q) {
    if (q.isEmpty) { setState(() => _filtered = List.from(_items)); return; }
    final query = q.toLowerCase();
    setState(() {
      _filtered = _items.where((item) {
        final m = item as Map<String, dynamic>;
        return m.values.any((v) => v.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient().get(widget.endpoint);
      final apiResp = ApiResponse.fromJson(response.data, null);
      if (apiResp.success && mounted) {
        final data = apiResp.data;
        setState(() {
          _items = data is List ? data : (data is Map ? (data['items'] as List? ?? []) : []);
          _loading = false;
        });
        _filter(_searchCtrl.text);
      }
    } catch (_) { if (mounted) { showServerErrorSnack(context); setState(() => _loading = false); } }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    return Scaffold(
      appBar: AppBar(title: Text(t(widget.titleKey))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(t('noData')))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _filter,
                        decoration: InputDecoration(
                          hintText: t('search'),
                          prefixIcon: const Icon(QasehIcons.searchCurved, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: AppColors.lightBlue.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(child: Text(t('noData')))
                          : RefreshIndicator(
                              onRefresh: _fetch,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final item = _filtered[i] as Map<String, dynamic>;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      title: Text(widget.itemTitle(item)),
                                      subtitle: widget.itemSubtitle != null ? Text(widget.itemSubtitle!(item) ?? '') : null,
                                      trailing: widget.itemTrailing != null
                                          ? (widget.onTrailingTap != null
                                              ? GestureDetector(onTap: () async { await widget.onTrailingTap!(item); _fetch(); }, child: widget.itemTrailing!(item))
                                              : widget.itemTrailing!(item))
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _AppSettingsPage extends StatefulWidget {
  const _AppSettingsPage();
  @override
  State<_AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<_AppSettingsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;

  String t(String key) => AppLocalizations.of(context)!.t(key);

  final _coinsController = TextEditingController();
  final _markupController = TextEditingController();
  final _tempEmailsController = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void dispose() {
    _coinsController.dispose();
    _markupController.dispose();
    _tempEmailsController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient().get(ApiConstants.settings);
      final apiResp = ApiResponse.fromJson(response.data, null);
      if (apiResp.success && apiResp.data != null && mounted) {
        final data = apiResp.data as Map<String, dynamic>;
        _coinsController.text = '${data['coins_per_usd'] ?? ''}';
        _markupController.text = '${data['default_markup'] ?? ''}';
        _tempEmailsController.text = '${data['temp_emails_per_month'] ?? ''}';
        setState(() { _data = data; _loading = false; });
      }
    } catch (_) { if (mounted) { showServerErrorSnack(context); setState(() => _loading = false); } }
  }

  Future<void> _save() async {
    final coins = int.tryParse(_coinsController.text);
    final markup = double.tryParse(_markupController.text);
    final emails = int.tryParse(_tempEmailsController.text);
    if (coins == null || markup == null || emails == null) {
      showAppSnack(context, t('invalidValues'), type: SnackType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await ApiClient().post(ApiConstants.settings, data: {
        'coins_per_usd': coins,
        'default_markup': markup,
        'temp_emails_per_month': emails,
      });
      final apiResp = ApiResponse.fromJson(response.data, null);
      if (apiResp.success && mounted) {
        showAppSnack(context, t('settingsSaved'), type: SnackType.success);
        _coinsController.text = coins.toString();
        _markupController.text = markup.toString();
        _tempEmailsController.text = emails.toString();
        if (_data != null) {
          _data!['coins_per_usd'] = coins;
          _data!['default_markup'] = markup;
          _data!['temp_emails_per_month'] = emails;
        }
        _fetch();
      }
    } catch (_) { if (mounted) showServerErrorSnack(context); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) return Scaffold(appBar: AppBar(title: Text(t('status'))), body: const Center(child: CircularProgressIndicator()));
    if (_data == null) return Scaffold(appBar: AppBar(title: Text(t('status'))), body: Center(child: Text(t('noData'))));

    return Scaffold(
      appBar: AppBar(title: Text(t('status'))),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(t('systemInfo')),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _data!.entries.where((e) => !_isEditable(e.key)).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 160, child: Text(_label(e.key), style: TextStyle(color: secondaryColor, fontSize: 13))),
                        Expanded(child: Text('${e.value}', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
            _sectionHeader(t('configuration')),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(t('coinsPerUsd'), _coinsController, TextInputType.number, t('coinsPerUsdHint')),
                    const SizedBox(height: 12),
                    _buildField(t('defaultMarkup'), _markupController, TextInputType.numberWithOptions(decimal: true), t('defaultMarkupHint')),
                    const SizedBox(height: 12),
                    _buildField(t('tempEmailsMonth'), _tempEmailsController, TextInputType.number, t('tempEmailsMonthHint')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(QasehIcons.tickSquareCurved, size: 18),
                        label: Text(_saving ? t('saving') : t('saveChanges')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.vividBlue, letterSpacing: 0.5)),
    );
  }

  bool _isEditable(String key) => key == 'coins_per_usd' || key == 'default_markup' || key == 'temp_emails_per_month';

  String _label(String key) {
    const labels = {
      'environment': 'Environment',
      'jwt_expiration_hours': 'JWT Expiry (hours)',
      'jwt_refresh_expiration_days': 'JWT Refresh (days)',
      'third_party_configured': '3rd Party Configured',
    };
    return labels[key] ?? key;
  }

  Widget _buildField(String label, TextEditingController ctrl, TextInputType kbType, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: kbType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: AppColors.lightBlue.withValues(alpha: 0.08),
      ),
    );
  }
}
