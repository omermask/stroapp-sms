import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/support_api.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  bool _isClosing = false;
  String? _error;
  Map<String, dynamic>? _ticket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(supportApiProvider);
      final data = await api.getTicketDetail(widget.ticketId);
      setState(() => _ticket = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final api = ref.read(supportApiProvider);
      await api.replyToTicket(widget.ticketId, message);
      _replyController.clear();
      await _fetchDetail();
    } catch (_) {
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إغلاق التذكرة'),
        content: const Text('هل أنت متأكد من إغلاق هذه التذكرة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isClosing = true);
    try {
      final api = ref.read(supportApiProvider);
      await api.closeTicket(widget.ticketId);
      await _fetchDetail();
    } catch (_) {
    } finally {
      setState(() => _isClosing = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.bluePrimary;
      case 'pending':
        return AppColors.warning;
      case 'answered':
        return AppColors.info;
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.muted;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'pending':
        return 'قيد الانتظار';
      case 'answered':
        return 'تم الرد';
      case 'closed':
        return 'مغلقة';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('تفاصيل التذكرة'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchDetail)
              : _ticket == null
                  ? const EmptyState(icon: QasehIcons.ticket_curved, message: 'لا توجد بيانات')
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _fetchDetail,
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.canvasLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.hairlineLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(QasehIcons.ticket_filled, size: 20, color: AppColors.bluePrimary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _ticket!['subject'] as String? ?? '',
                                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildInfoChip(
                                            Icons.category,
                                            _ticket!['category'] as String? ?? '',
                                          ),
                                          _buildInfoChip(
                                            Icons.flag,
                                            _ticket!['priority'] as String? ?? '',
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: _statusColor(_ticket!['status'] as String? ?? '').withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _statusLabel(_ticket!['status'] as String? ?? ''),
                                              style: AppTextStyles.caption.copyWith(
                                                color: _statusColor(_ticket!['status'] as String? ?? ''),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_ticket!['created_at'] != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'تاريخ الإنشاء: ${_ticket!['created_at']}',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('الردود', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                                const SizedBox(height: 8),
                                if (_ticket!['messages'] != null && (_ticket!['messages'] as List).isNotEmpty)
                                  ...(_ticket!['messages'] as List).map((msg) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.canvasLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.hairlineLight),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                (msg as Map)['is_admin'] == true
                                                    ? QasehIcons.profile_curved
                                                    : Icons.person_outline,
                                                size: 16,
                                                color: (msg)['is_admin'] == true
                                                    ? AppColors.bluePrimary
                                                    : AppColors.mutedStrong,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                (msg)['is_admin'] == true ? 'الدعم' : 'أنت',
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: (msg)['is_admin'] == true
                                                      ? AppColors.bluePrimary
                                                      : AppColors.mutedStrong,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                (msg)['created_at'] as String? ?? '',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            (msg)['message'] as String? ?? '',
                                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                                else
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.canvasLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.hairlineLight),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'لا توجد ردود بعد',
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            border: Border(top: BorderSide(color: AppColors.hairlineLight)),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                if ((_ticket!['status'] as String?) != 'closed')
                                  IconButton(
                                    icon: _isClosing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Icon(QasehIcons.close_square_curved, color: AppColors.error),
                                    onPressed: _isClosing ? null : _closeTicket,
                                    tooltip: 'إغلاق التذكرة',
                                  ),
                                Expanded(
                                  child: TextField(
                                    controller: _replyController,
                                    textDirection: TextDirection.rtl,
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                                    decoration: InputDecoration(
                                      hintText: 'اكتب ردك...',
                                      hintTextDirection: TextDirection.rtl,
                                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                                      filled: true,
                                      fillColor: AppColors.surfaceSoftLight,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: _isSending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bluePrimary),
                                        )
                                      : Icon(QasehIcons.send_curved, color: AppColors.bluePrimary),
                                  onPressed: _isSending ? null : _sendReply,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.hairlineLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mutedStrong),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
        ],
      ),
    );
  }
}
