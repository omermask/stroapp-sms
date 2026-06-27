import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/models/support_ticket.dart';
import '../../core/services/ticket_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../screens/ticket_detail_screen.dart';

class TabTickets extends StatefulWidget {
  const TabTickets({super.key});

  @override
  State<TabTickets> createState() => _TabTicketsState();
}

class _TabTicketsState extends State<TabTickets> {
  final _service = TicketService();
  final _scrollController = ScrollController();

  List<SupportTicket> _items = [];
  bool _loading = true;

  String t(String key) => AppLocalizations.of(context)!.t(key);
  bool _loadingMore = false;
  String? _error;
  String _statusFilter = '';

  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_loadingMore && !_loading) {
      setState(() => _loadingMore = true);
      _fetch(loadMore: true);
    }
  }

  Future<void> _fetch({bool refresh = false, bool loadMore = false}) async {
    if (refresh) {
      _items = [];
      setState(() => _loading = true);
    }
    final offset = loadMore ? _items.length : 0;
    try {
      final items = await _service.listTickets(
        limit: _pageSize,
        offset: offset,
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _items.addAll(items);
        } else {
          _items = items;
        }
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_items.isEmpty) _error = e.toString();
      });
      if (_items.isNotEmpty) showServerErrorSnack(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(t('supportTickets')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: t('filterAll'),
                    selected: _statusFilter == '',
                    onTap: () => setState(() {
                      _statusFilter = '';
                      _fetch(refresh: true);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t('filterOpen'),
                    selected: _statusFilter == 'open',
                    onTap: () => setState(() {
                      _statusFilter = 'open';
                      _fetch(refresh: true);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t('filterClosed'),
                    selected: _statusFilter == 'closed',
                    onTap: () => setState(() {
                      _statusFilter = 'closed';
                      _fetch(refresh: true);
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildBody(isDark, textColor, secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color textColor,
    Color secondaryColor,
  ) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      final t = AppLocalizations.of(context)!.t;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(QasehIcons.dangerTriangleCurved, size: 48),
              const SizedBox(height: 16),
              Text(t('serverError')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _fetch(refresh: true),
                icon: const Icon(QasehIcons.downloadCurved, size: 18),
                label: Text(t('retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(t('noTickets'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black38)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final ticket = _items[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(ticket.status).withValues(alpha: 0.2),
                child: Icon(
                  ticket.status == 'closed' ? QasehIcons.tickSquareFilled : QasehIcons.timeCircleCurved,
                  color: _statusColor(ticket.status),
                  size: 18,
                ),
              ),
              title: Text(
                ticket.subject,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '#${ticket.shortId} · ${ticket.category} · ${ticket.status}',
                style: TextStyle(color: secondaryColor, fontSize: 12),
              ),
              trailing: Text(
                ticket.createdAt != null && ticket.createdAt!.length >= 10
                    ? ticket.createdAt!.substring(0, 10)
                    : '',
                style: TextStyle(color: secondaryColor, fontSize: 11),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.caribbeanGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.caribbeanGreen : AppColors.cyprus.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.cyprus,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
