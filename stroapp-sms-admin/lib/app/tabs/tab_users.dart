import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import '../../core/models/user.dart';
import '../../core/services/users_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_colors.dart';

class TabUsers extends StatefulWidget {
  const TabUsers({super.key});

  @override
  State<TabUsers> createState() => _TabUsersState();
}

class _TabUsersState extends State<TabUsers> {
  final _service = UsersService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<User> _users = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String _search = '';
  String? _tierFilter;
  bool? _bannedFilter;
  String? _error;
  int _fetchVersion = 0;

  static const _tiers = ['freemium', 'payg', 'pro', 'custom'];
  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers({bool refresh = false}) async {
    if (_loadingMore) return;
    final version = ++_fetchVersion;
    if (refresh) {
      _page = 1;
      _users = [];
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
      final result = await _service.listUsers(
        page: _page,
        perPage: _perPage,
        search: _search,
        tier: _tierFilter,
        isBanned: _bannedFilter,
      );
      if (!mounted || version != _fetchVersion) return;
      setState(() {
        _users.addAll(result.users);
        _total = result.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || version != _fetchVersion) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_users.isEmpty) _error = e.toString();
      });
      if (_users.isNotEmpty) showServerErrorSnack(context);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_search != value) {
        _search = value;
        _fetchUsers(refresh: true);
      }
    });
  }

  void _setTierFilter(String? tier) {
    _tierFilter = _tierFilter == tier ? null : tier;
    _fetchUsers(refresh: true);
  }

  void _setBannedFilter(bool? banned) {
    _bannedFilter = _bannedFilter == banned ? null : banned;
    _fetchUsers(refresh: true);
  }

  Future<void> _showUserDetail(User user) async {
    await Navigator.of(context).push<bool>(_UserDetailRoute(user, _service));
    _fetchUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;

    return Scaffold(
      appBar: AppBar(title: Text(t('userManagement'))),
      body: Column(
        children: [
          _buildSearchBar(t),
          _buildFilterChips(t),
          Expanded(child: _buildBody(t)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppTextField(
        label: '',
        hintText: t('searchUsers'),
        controller: _searchController,
        prefixIcon: const Icon(QasehIcons.searchCurved),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterChips(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._tiers.map(
              (tr) => _filterChip(
                t(tr),
                _tierFilter == tr,
                () => _setTierFilter(tr),
              ),
            ),
            const SizedBox(width: 8),
            _filterChip(
              t('banned'),
              _bannedFilter == true,
              () => _setBannedFilter(true),
            ),
            const SizedBox(width: 8),
            _filterChip(
              t('active'),
              _bannedFilter == false,
              () => _setBannedFilter(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(fontSize: 12, color: selected ? Colors.white : null),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.vividBlue,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: selected
              ? AppColors.vividBlue
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.black26),
        ),
      ),
    );
  }

  Widget _buildBody(String Function(String) t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(t('serverError'), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _fetchUsers(refresh: true),
                icon: const Icon(QasehIcons.downloadCurved, size: 18),
                label: Text(t('retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text(
          t('noData'),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.black38,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchUsers(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _users.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _buildUserTile(_users[i], t);
        },
      ),
    );
  }

  bool get _hasMore => _users.length < _total;

  Widget _buildUserTile(User user, String Function(String) t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDetail(user),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: user.isBanned
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.caribbeanGreen.withValues(alpha: 0.15),
                child: Text(
                  user.initial,
                  style: TextStyle(
                    color: user.isBanned
                        ? Colors.red
                        : AppColors.caribbeanGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayNameOrEmail,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.coins} ${t('coins')} · ${t(user.tier)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.isBanned)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    QasehIcons.shieldFailCurved,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDetailRoute extends MaterialPageRoute<bool> {
  _UserDetailRoute(User user, UsersService service)
    : super(
        builder: (_) => _UserDetailScreen(user: user, service: service),
      );
}

class _UserDetailScreen extends StatefulWidget {
  final User user;
  final UsersService service;

  const _UserDetailScreen({required this.user, required this.service});

  @override
  State<_UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<_UserDetailScreen> {
  late User _user;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await widget.service.getUserDetail(_user.id);
      if (mounted) {
        setState(() {
          _user = detail;
          _loadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_user.displayNameOrEmail)),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(isDark, t),
                  const SizedBox(height: 20),
                  _buildInfoSection(isDark, t),
                  const SizedBox(height: 20),
                  _buildActionsSection(isDark, t),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(bool isDark, String Function(String) t) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: _user.isBanned
                ? Colors.red.withValues(alpha: 0.15)
                : AppColors.caribbeanGreen.withValues(alpha: 0.15),
            child: Text(
              _user.initial,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _user.isBanned ? Colors.red : AppColors.caribbeanGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _user.displayNameOrEmail,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          if (_user.email != null && _user.email != _user.displayName) ...[
            const SizedBox(height: 4),
            Text(
              _user.email!,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, String Function(String) t) {
    final items = <_InfoRow>[
      _InfoRow(QasehIcons.walletCurved, t('coins'), '${_user.coins}'),
      _InfoRow(
        QasehIcons.walletCurved,
        t('lifetimeCoins'),
        '${_user.lifetimeCoins}',
      ),
      _InfoRow(QasehIcons.swapCurved, t('tier'), t(_user.tier)),
      _InfoRow(
        QasehIcons.shieldFailCurved,
        t('banned'),
        _user.isBanned ? t('yes') : t('no'),
      ),
      _InfoRow(
        QasehIcons.tickSquareCurved,
        t('emailVerified'),
        _user.emailVerified ? t('yes') : t('no'),
      ),
      _InfoRow(
        QasehIcons.lockCurved,
        t('mfaEnabled'),
        _user.mfaEnabled ? t('yes') : t('no'),
      ),
      _InfoRow(
        QasehIcons.calendarCurved,
        t('createdAt'),
        _formatDate(_user.createdAt),
      ),
      if (_user.lastLoginAt != null)
        _InfoRow(
          QasehIcons.loginCurved,
          t('lastLogin'),
          _formatDate(_user.lastLoginAt!),
        ),
    ];

    if (_user.stats != null) {
      items.add(
        _InfoRow(
          QasehIcons.bagCurved,
          t('orders'),
          '${_user.stats!['order_count'] ?? '-'}',
        ),
      );
      items.add(
        _InfoRow(
          QasehIcons.swapCurved,
          t('transactions'),
          '${_user.stats!['transaction_count'] ?? '-'}',
        ),
      );
    }

    return _buildCard(
      isDark: isDark,
      child: Column(
        children: items.map((item) => _buildInfoRow(item, isDark)).toList(),
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: AppColors.vividBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isDark, String Function(String) t) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t('actions'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          _actionTile(
            QasehIcons.shieldFailCurved,
            _user.isBanned ? t('unban') : t('ban'),
            _user.isBanned ? Colors.green : Colors.red,
            () => _handleBanToggle(t),
          ),
          _actionTile(
            QasehIcons.walletCurved,
            t('adjustCoins'),
            AppColors.oceanBlue,
            () => _showAdjustCoinsDialog(t),
          ),
          _actionTile(
            QasehIcons.swapCurved,
            t('changeTier'),
            AppColors.vividBlue,
            () => _showChangeTierDialog(t),
          ),
          _actionTile(
            QasehIcons.deleteCurved,
            t('deleteUser'),
            Colors.red,
            () => _handleDelete(t),
          ),
          _actionTile(
            QasehIcons.closeSquareCurved,
            t('invalidateSessions'),
            Colors.orange,
            () => _handleInvalidateSessions(t),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      dense: true,
      onTap: onTap,
    );
  }

  Future<void> _handleBanToggle(String Function(String) t) async {
    try {
      await widget.service.toggleBan(_user.id);
      if (!mounted) return;
      showSuccessSnack(context, _user.isBanned ? 'unban' : 'ban');
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) showServerErrorSnack(context);
    }
  }

  void _handleDelete(String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('deleteUser')),
        content: Text(t('deleteWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.service.deleteUser(_user.id);
                if (!mounted) return;
                showSuccessSnack(context, 'deleteUser');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context, true);
                });
              } catch (_) {
                if (mounted) showServerErrorSnack(context);
              }
            },
            child: Text(t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAdjustCoinsDialog(String Function(String) t) {
    final coinsController = TextEditingController();
    final reasonController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('coinAdjustment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: t('coins'),
                hintText: 'e.g. 50 or -10',
                controller: coinsController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: t('reason'),
                hintText: t('reason'),
                controller: reasonController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () async {
                final amount = int.tryParse(coinsController.text);
                if (amount == null) {
                  setDialogState(() => errorText = t('invalidCoins'));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await widget.service.adjustCoins(
                    _user.id,
                    amount,
                    reasonController.text,
                  );
                  if (!mounted) return;
                  showSuccessSnack(context, 'adjustCoins');
                  setState(
                    () => _user = User(
                      id: _user.id,
                      email: _user.email,
                      displayName: _user.displayName,
                      photoUrl: _user.photoUrl,
                      coins: _user.coins + amount,
                      lifetimeCoins: _user.lifetimeCoins,
                      tier: _user.tier,
                      isAdmin: _user.isAdmin,
                      isBanned: _user.isBanned,
                      isActive: _user.isActive,
                      emailVerified: _user.emailVerified,
                      mfaEnabled: _user.mfaEnabled,
                      onboardingCompleted: _user.onboardingCompleted,
                      lastLoginAt: _user.lastLoginAt,
                      createdAt: _user.createdAt,
                      updatedAt: _user.updatedAt,
                      stats: _user.stats,
                    ),
                  );
                } catch (_) {
                  if (mounted) showServerErrorSnack(context);
                }
              },
              child: Text(t('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeTierDialog(String Function(String) t) {
    String selected = _user.tier;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('changeTier')),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            items: const ['freemium', 'payg', 'pro', 'custom']
                .map((tr) => DropdownMenuItem(value: tr, child: Text(t(tr))))
                .toList(),
            onChanged: (v) => setDialogState(() => selected = v ?? selected),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await widget.service.changeTier(_user.id, selected);
                  if (!mounted) return;
                  showSuccessSnack(context, 'changeTier');
                  setState(
                    () => _user = User(
                      id: _user.id,
                      email: _user.email,
                      displayName: _user.displayName,
                      photoUrl: _user.photoUrl,
                      coins: _user.coins,
                      lifetimeCoins: _user.lifetimeCoins,
                      tier: selected,
                      isAdmin: _user.isAdmin,
                      isBanned: _user.isBanned,
                      isActive: _user.isActive,
                      emailVerified: _user.emailVerified,
                      mfaEnabled: _user.mfaEnabled,
                      onboardingCompleted: _user.onboardingCompleted,
                      lastLoginAt: _user.lastLoginAt,
                      createdAt: _user.createdAt,
                      updatedAt: _user.updatedAt,
                      stats: _user.stats,
                    ),
                  );
                } catch (_) {
                  if (mounted) showServerErrorSnack(context);
                }
              },
              child: Text(t('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  void _handleInvalidateSessions(String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('invalidateSessions')),
        content: Text(t('invalidateWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.service.invalidateSessions(_user.id);
                if (!mounted) return;
                showSuccessSnack(context, 'invalidateSessions');
              } catch (_) {
                if (mounted) showServerErrorSnack(context);
              }
            },
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: child,
    );
  }

  String _formatDate(String iso) {
    final idx = iso.indexOf('T');
    return idx > 0 ? iso.substring(0, idx) : iso;
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}
