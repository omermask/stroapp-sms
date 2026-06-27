import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/models/order.dart';
import '../../core/models/transaction.dart';
import '../../core/services/orders_service.dart';
import '../../core/services/transactions_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../screens/order_detail_screen.dart';
import '../screens/transaction_detail_screen.dart';

class TabOrders extends StatefulWidget {
  const TabOrders({super.key});

  @override
  State<TabOrders> createState() => _TabOrdersState();
}

class _TabOrdersState extends State<TabOrders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('ordersList')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('orders')),
            Tab(text: t('transactions')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_OrdersTab(), _TransactionsTab()],
      ),
    );
  }
}

// ── Orders Tab ──

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  final _service = OrdersService();
  final _scrollController = ScrollController();

  List<Order> _items = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _fetchVersion = 0;

  static const _perPage = 20;

  bool get _hasMore => _items.length < _total;

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
    if (_hasMore && !_loadingMore && !_loading) {
      _page++;
      _fetch();
    }
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_loadingMore) return;
    final version = ++_fetchVersion;
    if (refresh) {
      _page = 1;
      _items = [];
    }
    final isFirstPage = _page == 1;
    if (isFirstPage) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final result = await _service.listOrders(page: _page, limit: _perPage);
      if (!mounted || version != _fetchVersion) return;
      setState(() {
        _items.addAll(result.orders);
        _total = result.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || version != _fetchVersion) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_items.isEmpty) _error = e.toString();
      });
      if (_items.isNotEmpty) showServerErrorSnack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                QasehIcons.dangerTriangleCurved,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(t('serverError'), textAlign: TextAlign.center),
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
        child: Text(
          t('noData'),
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _OrderTile(
            order: _items[i],
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: _items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  final bool isDark;
  final VoidCallback? onTap;

  const _OrderTile({required this.order, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    switch (order.status) {
      case 'completed':
        statusIcon = QasehIcons.tickSquareFilled;
        statusColor = AppColors.statusGreen;
      case 'pending':
        statusIcon = QasehIcons.timeCircleCurved;
        statusColor = AppColors.statusOrange;
      default:
        statusIcon = QasehIcons.dangerTriangleCurved;
        statusColor = AppColors.statusRed;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.lightBlue.withValues(alpha: 0.2),
            child: Text(
              order.serviceLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            '${order.service} — ${order.country}',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            '${order.status} · ${order.costCoins} coins',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          trailing: Icon(statusIcon, color: statusColor, size: 20),
        ),
      ),
    );
  }
}

// ── Transactions Tab ──

class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab();

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  final _service = TransactionsService();
  final _scrollController = ScrollController();

  List<Transaction> _items = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _fetchVersion = 0;

  static const _perPage = 20;

  bool get _hasMore => _items.length < _total;

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
    if (_hasMore && !_loadingMore && !_loading) {
      _page++;
      _fetch();
    }
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_loadingMore) return;
    final version = ++_fetchVersion;
    if (refresh) {
      _page = 1;
      _items = [];
    }
    final isFirstPage = _page == 1;
    if (isFirstPage) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final result = await _service.listTransactions(
        page: _page,
        limit: _perPage,
      );
      if (!mounted || version != _fetchVersion) return;
      setState(() {
        _items.addAll(result.transactions);
        _total = result.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || version != _fetchVersion) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_items.isEmpty) _error = e.toString();
      });
      if (_items.isNotEmpty) showServerErrorSnack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                QasehIcons.dangerTriangleCurved,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(t('serverError'), textAlign: TextAlign.center),
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
        child: Text(
          t('noData'),
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _TransactionTile(
            transaction: _items[i],
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transaction: _items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  final VoidCallback? onTap;

  const _TransactionTile(
      {required this.transaction, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.isDeposit;
    final color = isPositive ? AppColors.statusGreen : AppColors.statusRed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(
              isPositive ? QasehIcons.arrowDownCurved : QasehIcons.arrowUpCurved,
              color: color,
              size: 18,
            ),
          ),
          title: Text(
            '${isPositive ? '+' : ''}${transaction.amount} coins',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            transaction.description ?? '',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          trailing: Text(
            transaction.createdAt.length >= 10
                ? transaction.createdAt.substring(0, 10)
                : transaction.createdAt,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}


