import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/models/support_ticket.dart';
import '../../core/services/ticket_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _service = TicketService();
  final _replyController = TextEditingController();
  SupportTicket? _ticket;
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket = await _service.getTicketDetail(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.replyToTicket(widget.ticketId, text);
      _replyController.clear();
      await _fetch();
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Ticket'),
        content: const Text('Are you sure you want to close this ticket?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.closeTicket(widget.ticketId);
      await _fetch();
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  Future<void> _assignTicket() async {
    final adminId = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Assign Ticket'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Admin ID',
              hintText: 'Enter admin user ID',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
    if (adminId == null || adminId.isEmpty) return;
    try {
      await _service.assignTicket(widget.ticketId, adminId);
      await _fetch();
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.statusGreen;
      case 'closed':
        return AppColors.statusRed;
      default:
        return AppColors.statusOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) return Scaffold(appBar: AppBar(title: Text(t('ticket'))), body: const Center(child: CircularProgressIndicator()));
    if (_error != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('ticket'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(QasehIcons.dangerTriangleCurved, size: 48),
              const SizedBox(height: 16),
              Text(t('serverError')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetch,
                icon: const Icon(QasehIcons.downloadCurved, size: 18),
                label: Text(t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final ticket = _ticket!;
    final isClosed = ticket.status == 'closed';

    return Scaffold(
      appBar: AppBar(
        title: Text('#${ticket.shortId} — ${ticket.subject}'),
        actions: isClosed
            ? null
            : [
                IconButton(
                  tooltip: t('assign'),
                  onPressed: _assignTicket,
                  icon: const Icon(QasehIcons.profileCurved, size: 20),
                ),
                IconButton(
                  tooltip: t('close'),
                  onPressed: _closeTicket,
                  icon: const Icon(QasehIcons.closeSquareCurved, size: 20),
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(ticket.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ticket.status.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(ticket.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ticket.priority.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.oceanBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.caribbeanGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ticket.category,
                                style: TextStyle(
                                  color: AppColors.cyprus,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Category: ${ticket.category}', style: TextStyle(color: secondaryColor, fontSize: 13)),
                        const SizedBox(height: 12),
                        Text(ticket.message, style: TextStyle(color: textColor, fontSize: 15)),
                        if (ticket.assignedTo != null) ...[
                          const SizedBox(height: 8),
                          Text('${t('assignedTo')}: ${ticket.assignedTo}', style: TextStyle(color: secondaryColor, fontSize: 12)),
                        ],
                        const SizedBox(height: 8),
                        if (ticket.createdAt != null)
                          Text('Created: ${ticket.createdAt!.length >= 10 ? ticket.createdAt!.substring(0, 10) : ticket.createdAt!}',
                              style: TextStyle(color: secondaryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(t('replies'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...ticket.replies.map((r) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  r.isAdmin ? QasehIcons.shieldDoneCurved : QasehIcons.profileCurved,
                                  size: 16,
                                  color: r.isAdmin ? AppColors.oceanBlue : AppColors.statusOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(r.isAdmin ? t('admin') : t('user'),
                                    style: TextStyle(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                if (r.createdAt != null)
                                  Text(r.createdAt!.length >= 10 ? r.createdAt!.substring(0, 10) : r.createdAt!,
                                      style: TextStyle(color: secondaryColor, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.message, style: TextStyle(color: textColor, fontSize: 14)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
          if (!isClosed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(hintText: t('typeReply'), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_sending)
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton.filled(
                      onPressed: _sendReply,
                      icon: const Icon(QasehIcons.sendCurved, size: 20),
                    ),
                ],
              ),
            ),
        ],
      ),

    );
  }
}
