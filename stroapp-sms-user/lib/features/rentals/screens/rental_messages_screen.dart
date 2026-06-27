import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/rentals_api.dart';
import '../../../core/api/api_exceptions.dart';

class RentalMessagesScreen extends ConsumerStatefulWidget {
  final String rentalId;

  const RentalMessagesScreen({super.key, required this.rentalId});

  @override
  ConsumerState<RentalMessagesScreen> createState() => _RentalMessagesScreenState();
}

class _RentalMessagesScreenState extends ConsumerState<RentalMessagesScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMessages());
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final data = await ref.read(rentalsApiProvider).getRentalMessages(widget.rentalId);
      if (mounted) {
        setState(() {
          _messages = data.cast<Map<String, dynamic>>();
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل الرسائل');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('رسائل الإيجار'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null && _messages.isEmpty) {
      return CustomErrorWidget(message: _error!, onRetry: _fetchMessages);
    }

    if (_messages.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchMessages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const EmptyState(
                icon: QasehIcons.message_curved,
                message: 'لا توجد رسائل بعد',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final from = msg['from']?.toString() ?? msg['sender']?.toString() ?? 'مرسل';
          final text = msg['text']?.toString() ?? msg['message']?.toString() ?? '—';
          final timestamp = msg['timestamp']?.toString() ?? msg['created_at']?.toString() ?? '';
          final isIncoming = from.toLowerCase() != 'me' && from.toLowerCase() != 'you';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: isIncoming ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isIncoming) const SizedBox(width: 48),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isIncoming ? AppColors.canvasLight : AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isIncoming ? Radius.zero : const Radius.circular(16),
                        bottomRight: isIncoming ? const Radius.circular(16) : Radius.zero,
                      ),
                      border: isIncoming ? Border.all(color: AppColors.hairlineLight) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isIncoming)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              from,
                              style: AppTextStyles.caption.copyWith(color: AppColors.bluePrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        Text(
                          text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isIncoming ? AppColors.ink : AppColors.onPrimary,
                          ),
                        ),
                        if (timestamp.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timestamp,
                              style: AppTextStyles.caption.copyWith(
                                color: isIncoming ? AppColors.mutedStrong : AppColors.onPrimary.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isIncoming) const SizedBox(width: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}
