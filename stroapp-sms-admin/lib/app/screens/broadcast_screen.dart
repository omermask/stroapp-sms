import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  String _selectedTier = 'freemium';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final payload = {
        'title': _titleCtrl.text,
        'body': _bodyCtrl.text,
        'notification_type': 'info',
      };
      final path = _target == 'tier'
          ? ApiConstants.broadcastTier
          : ApiConstants.broadcastNotification;
      if (_target == 'tier') {
        payload['tier'] = _selectedTier;
      }
      final r = await ApiClient().postV4(path, data: payload);
      final resp = ApiResponse.fromJson(r.data, null);
      if (resp.success && mounted) {
        showSuccessSnack(context, '${t('actionSuccess')} — ${resp.data?['user_count'] ?? ''} users');
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String t(String key) => AppLocalizations.of(context)!.t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('broadcast'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('sendNotification'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'all', label: Text(t('sendToAll'))),
              ButtonSegment(value: 'tier', label: Text(t('sendToTier'))),
            ],
            selected: {_target},
            onSelectionChanged: (v) => setState(() => _target = v.first),
          ),
          const SizedBox(height: 16),
          if (_target == 'tier') ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedTier,
              decoration: InputDecoration(labelText: t('selectTier')),
              items: ['freemium', 'payg', 'pro', 'custom']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedTier = v!),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(labelText: t('title'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: InputDecoration(labelText: t('message'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_sending ? t('loading') : t('sendNotification')),
          ),
        ],
      ),
    );
  }
}
