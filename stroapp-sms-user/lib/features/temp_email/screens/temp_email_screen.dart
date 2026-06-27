import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/email_provider.dart';

class TempEmailScreen extends ConsumerStatefulWidget {
  const TempEmailScreen({super.key});

  @override
  ConsumerState<TempEmailScreen> createState() => _TempEmailScreenState();
}

class _TempEmailScreenState extends ConsumerState<TempEmailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailProvider.notifier).fetchTempEmail();
      ref.read(emailProvider.notifier).fetchMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        backgroundColor: AppColors.canvasLight,
        elevation: 0,
        centerTitle: true,
        title: Text('البريد المؤقت', style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrongLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(QasehIcons.arrow_right_curved, size: 20, color: AppColors.ink),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              ref.read(emailProvider.notifier).fetchTempEmail();
              ref.read(emailProvider.notifier).fetchMessages();
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceStrongLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, size: 20, color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: state.isLoading && state.emailAddress == null
          ? const LoadingIndicator()
          : state.error != null && state.emailAddress == null
              ? CustomErrorWidget(
                  message: state.error!,
                  onRetry: () {
                    ref.read(emailProvider.notifier).fetchTempEmail();
                    ref.read(emailProvider.notifier).fetchMessages();
                  },
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref.read(emailProvider.notifier).fetchTempEmail();
                    await ref.read(emailProvider.notifier).fetchMessages();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.emailAddress != null)
                          _buildEmailCard(state.emailAddress!),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(QasehIcons.message_curved, size: 20, color: AppColors.ink),
                            const SizedBox(width: 8),
                            Text('الرسائل', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                            const Spacer(),
                            if (state.messages.isNotEmpty)
                              Text('${state.messages.length} رسالة', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.messages.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineLight),
                            ),
                            child: Column(
                              children: [
                                Icon(QasehIcons.message_curved, size: 40, color: AppColors.mutedStrong),
                                const SizedBox(height: 12),
                                Text('لا توجد رسائل بعد', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                const SizedBox(height: 4),
                                Text('سيتم عرض الرسائل هنا عند وصولها', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineLight),
                            ),
                            child: Column(
                              children: state.messages.asMap().entries.map((entry) {
                                final i = entry.key;
                                final msg = entry.value;
                                return Column(
                                  children: [
                                    if (i > 0) Divider(height: 1, color: AppColors.hairlineLight),
                                    _buildMessageItem(msg),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmailCard(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(QasehIcons.message_curved, size: 22, color: AppColors.onPrimary),
              const SizedBox(width: 8),
              Text('بريدك المؤقت', style: AppTextStyles.titleSmall.copyWith(color: AppColors.onPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ البريد الإلكتروني')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(QasehIcons.document_curved, size: 14, color: AppColors.onPrimary),
                      const SizedBox(width: 4),
                      Text('نسخ', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SelectableText(
            email,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              await ref.read(emailProvider.notifier).deleteEmail();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف البريد المؤقت')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(QasehIcons.delete_curved, size: 16, color: AppColors.onPrimary),
                  const SizedBox(width: 6),
                  Text('حذف البريد', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final from = msg['from']?.toString() ?? 'غير معروف';
    final subject = msg['subject']?.toString() ?? '(بدون موضوع)';
    final preview = msg['preview']?.toString() ?? msg['body']?.toString() ?? '';
    final time = msg['time']?.toString() ?? msg['created_at']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceStrongLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(QasehIcons.message_curved, size: 20, color: AppColors.bluePrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        from,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (time.isNotEmpty)
                      Text(
                        time.length > 10 ? time.substring(0, 10) : time,
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subject,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.bodyLight),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
