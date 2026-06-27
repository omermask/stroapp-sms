import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    return Scaffold(
      appBar: AppBar(title: Text(t('exportData'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ExportTile(title: t('users'), endpoint: ApiConstants.exportUsers, context: context),
          _ExportTile(title: t('transactions'), endpoint: ApiConstants.exportTransactions, context: context),
          _ExportTile(title: t('payments'), endpoint: ApiConstants.exportPayments, context: context),
          _ExportTile(title: t('auditLogs'), endpoint: ApiConstants.exportAuditLogs, context: context),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final String title;
  final String endpoint;
  final BuildContext context;

  const _ExportTile({required this.title, required this.endpoint, required this.context});

  Future<void> _download() async {
    try {
      final response = await ApiClient().getV4(endpoint, queryParameters: {'format': 'csv', 'limit': 10000});
      final csvData = response.data is String ? response.data as String : response.data.toString();
      await Clipboard.setData(ClipboardData(text: csvData));
      if (context.mounted) {
        final loc = AppLocalizations.of(context)!.t;
        showSuccessSnack(context, '${loc('csvCopied')} (${csvData.length} chars)');
      }
    } catch (_) {
      if (context.mounted) showServerErrorSnack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.download),
        title: Text('${t('exportData')} $title'),
        subtitle: Text(t('csvClipboard')),
        trailing: ElevatedButton.icon(
          onPressed: _download,
          icon: const Icon(Icons.copy, size: 16),
          label: Text(t('copyCsv')),
        ),
      ),
    );
  }
}
