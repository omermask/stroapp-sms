import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';
import '../../../core/models/webhook_model.dart';

class WebhooksScreen extends ConsumerStatefulWidget {
  const WebhooksScreen({super.key});

  @override
  ConsumerState<WebhooksScreen> createState() => _WebhooksScreenState();
}

class _WebhooksScreenState extends ConsumerState<WebhooksScreen> {
  List<WebhookModel> _webhooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWebhooks();
  }

  Future<void> _fetchWebhooks() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ref.read(settingsApiProvider).getWebhooks();
      if (mounted) {
        setState(() {
          _webhooks = data.map((e) => WebhookModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _createWebhook() async {
    final urlController = TextEditingController();
    final secretController = TextEditingController();
    final selectedEvents = <String>{};

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.canvasLight,
          title: const Text('Webhook جديد', style: AppTextStyles.titleMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: urlController,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: 'URL',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                      filled: true,
                      fillColor: AppColors.surfaceSoftLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.hairlineLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: secretController,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Secret (اختياري)',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                      filled: true,
                      fillColor: AppColors.surfaceSoftLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.hairlineLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('الأحداث:', style: AppTextStyles.labelSmall.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 4),
                  ...['sms.received', 'sms.completed', 'sms.expired', 'sms.cancelled', 'order.purchased', 'order.completed', 'user.deposit'].map((event) => CheckboxListTile(
                    value: selectedEvents.contains(event),
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(event, style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true) { selectedEvents.add(event); } else { selectedEvents.remove(event); }
                      });
                    },
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong))),
            TextButton(
              onPressed: selectedEvents.isEmpty || urlController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, {
                      'url': urlController.text.trim(),
                      'events': selectedEvents.toList(),
                      'secret': secretController.text.trim().isEmpty ? null : secretController.text.trim(),
                    }),
              child: const Text('إنشاء', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await ref.read(settingsApiProvider).createWebhook(
          result['url'] as String,
          result['events'] as List<String>,
          result['secret'] as String?,
        );
        await _fetchWebhooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء webhook بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _editWebhook(WebhookModel webhook) async {
    final urlController = TextEditingController(text: webhook.url);
    final selectedEvents = webhook.events.toSet();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.canvasLight,
          title: const Text('تعديل Webhook', style: AppTextStyles.titleMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: urlController,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: 'URL',
                      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                      filled: true,
                      fillColor: AppColors.surfaceSoftLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.hairlineLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  Text('الأحداث:', style: AppTextStyles.labelSmall.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 4),
                  ...['sms.received', 'sms.completed', 'sms.expired', 'sms.cancelled', 'order.purchased', 'order.completed', 'user.deposit'].map((event) => CheckboxListTile(
                    value: selectedEvents.contains(event),
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(event, style: AppTextStyles.caption.copyWith(color: AppColors.ink)),
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true) { selectedEvents.add(event); } else { selectedEvents.remove(event); }
                      });
                    },
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong))),
            TextButton(
              onPressed: selectedEvents.isEmpty || urlController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, {
                      'url': urlController.text.trim(),
                      'events': selectedEvents.toList(),
                    }),
              child: const Text('حفظ', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await ref.read(settingsApiProvider).updateWebhook(
          webhook.id,
          result['url'] as String,
          result['events'] as List<String>,
          true,
        );
        await _fetchWebhooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث webhook بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _deleteWebhook(WebhookModel webhook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('حذف Webhook', style: AppTextStyles.titleMedium),
        content: Text('هل أنت متأكد من حذف webhook:\n${webhook.url}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(settingsApiProvider).deleteWebhook(webhook.id);
        await _fetchWebhooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف webhook')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _toggleWebhook(WebhookModel webhook) async {
    try {
      await ref.read(settingsApiProvider).updateWebhook(
        webhook.id,
        null,
        null,
        !webhook.isActive,
      );
      await _fetchWebhooks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('Webhooks'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _createWebhook,
        child: Icon(QasehIcons.plus_curved, color: AppColors.onPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchWebhooks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(QasehIcons.danger_triangle_curved, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _fetchWebhooks, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : _webhooks.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(QasehIcons.send_curved, size: 48, color: AppColors.mutedStrong),
                                const SizedBox(height: 12),
                                Text('لا توجد Webhooks', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                const SizedBox(height: 4),
                                Text('اضغط على + لإنشاء webhook جديد', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _webhooks.length,
                        itemBuilder: (context, index) {
                          final webhook = _webhooks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineLight),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: webhook.isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.muted.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          QasehIcons.send_curved,
                                          size: 20,
                                          color: webhook.isActive ? AppColors.success : AppColors.mutedStrong,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              webhook.url,
                                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              webhook.events.join('، '),
                                              style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: webhook.isActive,
                                        activeTrackColor: AppColors.success,
                                        onChanged: (_) => _toggleWebhook(webhook),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(QasehIcons.edit_curved, size: 18, color: AppColors.bluePrimary),
                                        onPressed: () => _editWebhook(webhook),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: Icon(QasehIcons.delete_curved, size: 18, color: AppColors.error),
                                        onPressed: () => _deleteWebhook(webhook),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
