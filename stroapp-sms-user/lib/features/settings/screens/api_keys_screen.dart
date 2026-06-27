import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/mfa_verify_dialog.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/services/mfa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';

class ApiKeysScreen extends ConsumerStatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  ConsumerState<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends ConsumerState<ApiKeysScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).fetchApiKeys();
    });
  }

  Future<void> _createKey() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('مفتاح API جديد', style: AppTextStyles.titleMedium),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'اسم المفتاح',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
            filled: true,
            fillColor: AppColors.surfaceSoftLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.hairlineLight),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('إنشاء', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _doCreateKey(name);
    }
  }

  Future<void> _doCreateKey(String name) async {
    try {
      await ref.read(settingsProvider.notifier).createApiKey(name);
    } on MfaRequiredException {
      if (!mounted) return;
      final token = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MfaVerifyDialog(),
      );
      if (token != null && mounted) {
        ref.read(mfaTokenProvider.notifier).state = token;
        await _doCreateKey(name);
      }
    }
  }

  Future<void> _deleteKey(String keyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('حذف مفتاح API', style: AppTextStyles.titleMedium),
        content: const Text('هل أنت متأكد من حذف هذا المفتاح؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _doDeleteKey(keyId);
    }
  }

  Future<void> _doDeleteKey(String keyId) async {
    try {
      await ref.read(settingsProvider.notifier).deleteApiKey(keyId);
    } on MfaRequiredException {
      if (!mounted) return;
      final token = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MfaVerifyDialog(),
      );
      if (token != null && mounted) {
        ref.read(mfaTokenProvider.notifier).state = token;
        await _doDeleteKey(keyId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('مفاتيح API'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _createKey,
        child: Icon(QasehIcons.add_user_curved, color: AppColors.onPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(settingsProvider.notifier).fetchApiKeys(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(QasehIcons.danger_triangle_curved, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(state.error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.read(settingsProvider.notifier).fetchApiKeys(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : state.apiKeys.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(QasehIcons.shield_done_curved, size: 48, color: AppColors.mutedStrong),
                                const SizedBox(height: 12),
                                Text('لا توجد مفاتيح API', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                const SizedBox(height: 4),
                                Text('اضغط على الزر + لإنشاء مفتاح جديد', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.apiKeys.length,
                        itemBuilder: (context, index) {
                          final key = state.apiKeys[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineLight),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: key.isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      QasehIcons.shield_done_curved,
                                      size: 20,
                                      color: key.isActive ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(key.name, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                                        const SizedBox(height: 4),
                                        if (key.prefix != null)
                                          Text(
                                            '${key.prefix}...',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong, fontFamily: 'monospace'),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: key.isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                key.isActive ? 'نشط' : 'غير نشط',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: key.isActive ? AppColors.success : AppColors.error,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            if (key.lastUsedAt != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                'آخر استخدام: ${_formatDate(key.lastUsedAt!)}',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong, fontSize: 11),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(QasehIcons.delete_curved, size: 20, color: AppColors.error),
                                    onPressed: () => _deleteKey(key.id),
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
