import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/utils/qaseh_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../screens/login_screen.dart';

class TabHome extends StatefulWidget {
  const TabHome({super.key});

  @override
  State<TabHome> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().get(ApiConstants.dashboard);
      final apiResp = ApiResponse.fromJson(response.data, null);
      if (apiResp.success && apiResp.data != null) {
        if (mounted) {
          setState(() {
            _data = apiResp.data as Map<String, dynamic>;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = apiResp.error?.message;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'serverError';
          _loading = false;
        });
      }
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('dashboard')),
          actions: [
            IconButton(
              icon: const Icon(QasehIcons.downloadCurved),
              onPressed: _loading ? null : _fetchDashboard,
            ),
            IconButton(
              icon: const Icon(QasehIcons.logoutCurved),
              onPressed: _logout,
            ),
          ],
        ),
        body: _buildBody(t, isDark),
      ),
    );
  }

  Widget _buildBody(String Function(String) t, bool isDark) {
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
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(t('serverError'), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchDashboard,
                icon: const Icon(QasehIcons.downloadCurved, size: 18),
                label: Text(t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final analytics = _data?['analytics'] as Map<String, dynamic>?;
    final today = analytics?['today'] as Map<String, dynamic>?;
    final trend = analytics?['trend'] as List<dynamic>?;

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                isDark,
                t('dashboard'),
                QasehIcons.activityCurved,
              ),
              const SizedBox(height: 20),
              _buildOverviewRow(isDark, t, today),
              const SizedBox(height: 20),
              _buildSectionTitle(
                isDark,
                t('totalUsers'),
                QasehIcons.twoUserCurved,
              ),
              const SizedBox(height: 10),
              _buildUserSection(isDark, t, today),
              const SizedBox(height: 20),
              _buildSectionTitle(
                isDark,
                t('totalTransactions'),
                QasehIcons.swapCurved,
              ),
              const SizedBox(height: 10),
              _buildTransactionSection(isDark, t, today),
              const SizedBox(height: 20),
              _buildSectionTitle(
                isDark,
                t('totalRevenue'),
                QasehIcons.walletCurved,
              ),
              const SizedBox(height: 10),
              _buildRevenueSection(isDark, t, today),
              if (trend != null && trend.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSectionTitle(
                  isDark,
                  t('newUsers'),
                  QasehIcons.twoUserCurved,
                ),
                const SizedBox(height: 10),
                _buildTrendChart(
                  isDark,
                  trend,
                  t,
                  'new_users',
                  AppColors.vividBlue,
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(
                  isDark,
                  t('todayRevenue'),
                  QasehIcons.walletCurved,
                ),
                const SizedBox(height: 10),
                _buildRevenueDonut(isDark, trend),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.vividBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.vividBlue),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(
    bool isDark,
    String Function(String) t,
    Map<String, dynamic>? today,
  ) {
    final items = [
      _OVData(
        QasehIcons.twoUserCurved,
        _fmtNum(_data?['total_users']),
        t('totalUsers'),
        AppColors.vividBlue,
      ),
      _OVData(
        QasehIcons.bagCurved,
        _fmtNum(_data?['total_orders']),
        t('totalOrders'),
        AppColors.caribbeanGreen,
      ),
      _OVData(
        QasehIcons.walletCurved,
        '${_fmtNum(_data?['total_revenue'])} ${t('coins')}',
        t('totalRevenue'),
        AppColors.oceanBlue,
      ),
      _OVData(
        QasehIcons.workCurved,
        _fmtNum(_data?['active_providers']),
        t('activeProviders'),
        AppColors.lightBlue,
      ),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 20, color: item.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetricGrid(bool isDark, List<_MetricData> metrics) {
    const gap = 8.0;
    return Column(
      children: [
        for (int i = 0; i < metrics.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < metrics.length ? gap : 0),
            child: i + 1 < metrics.length
                ? Row(
                    children: [
                      Expanded(child: _buildMetricTile(isDark, metrics[i])),
                      const SizedBox(width: gap),
                      Expanded(child: _buildMetricTile(isDark, metrics[i + 1])),
                    ],
                  )
                : _buildMetricTile(isDark, metrics[i]),
          ),
      ],
    );
  }

  Widget _buildMetricTile(bool isDark, _MetricData m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(m.icon, size: 17, color: m.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  m.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  m.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(
    bool isDark,
    String Function(String) t,
    Map<String, dynamic>? today,
  ) {
    return _buildMetricGrid(isDark, [
      _MetricData(
        _fmtNum(_data?['total_users']),
        t('totalUsers'),
        QasehIcons.twoUserCurved,
        AppColors.vividBlue,
      ),
      _MetricData(
        _fmtNum(_data?['total_orders']),
        t('totalOrders'),
        QasehIcons.bagCurved,
        AppColors.vividBlue,
      ),
      _MetricData(
        '${today?['new_users'] ?? 0}',
        t('newUsers'),
        QasehIcons.addUserCurved,
        AppColors.caribbeanGreen,
      ),
      _MetricData(
        _fmtNum(_data?['active_orders']),
        t('activeOrders'),
        QasehIcons.documentCurved,
        AppColors.caribbeanGreen,
      ),
    ]);
  }

  Widget _buildTransactionSection(
    bool isDark,
    String Function(String) t,
    Map<String, dynamic>? today,
  ) {
    return _buildMetricGrid(isDark, [
      _MetricData(
        _fmtNum(_data?['total_transactions']),
        t('totalTransactions'),
        QasehIcons.swapCurved,
        AppColors.oceanBlue,
      ),
      _MetricData(
        '${today?['verifications'] ?? 0}',
        t('sales'),
        QasehIcons.tickSquareCurved,
        AppColors.oceanBlue,
      ),
      _MetricData(
        _fmtNum(_data?['active_orders']),
        t('activeOrders'),
        QasehIcons.bagCurved,
        AppColors.caribbeanGreen,
      ),
      _MetricData(
        _fmtNum(_data?['active_providers']),
        t('activeProviders'),
        QasehIcons.workCurved,
        AppColors.lightBlue,
      ),
    ]);
  }

  Widget _buildRevenueSection(
    bool isDark,
    String Function(String) t,
    Map<String, dynamic>? today,
  ) {
    return _buildMetricGrid(isDark, [
      _MetricData(
        '${_fmtNum(_data?['total_revenue'])} ${t('coins')}',
        t('totalRevenue'),
        QasehIcons.walletCurved,
        AppColors.oceanBlue,
      ),
      _MetricData(
        '${today?['revenue'] ?? 0} ${t('coins')}',
        t('todayRevenue'),
        QasehIcons.walletCurved,
        AppColors.caribbeanGreen,
      ),
      _MetricData(
        _fmtNum(_data?['total_orders']),
        t('totalOrders'),
        QasehIcons.bagCurved,
        AppColors.vividBlue,
      ),
      _MetricData(
        _fmtNum(_data?['total_transactions']),
        t('totalTransactions'),
        QasehIcons.swapCurved,
        AppColors.lightBlue,
      ),
    ]);
  }

  Widget _buildTrendChart(
    bool isDark,
    List<dynamic> trend,
    String Function(String) t,
    String field,
    Color barColor,
  ) {
    final last7 = trend.length >= 7 ? trend.sublist(trend.length - 7) : trend;
    final labels = last7.map((e) {
      final date = e['date'] as String? ?? '';
      if (date.length >= 10) {
        final parts = date.split('-');
        if (parts.length >= 3) return '${parts[2]}/${parts[1]}';
      }
      return date;
    }).toList();

    final values = last7
        .map((e) => (e[field] as num?)?.toDouble() ?? 0)
        .toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal < 10 ? 10.0 : (maxVal * 1.25);

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 16, right: 8, left: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${labels[groupIndex]}\n${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labels[idx],
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  _fmtCompact(value),
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.black12,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            last7.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: barColor,
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueDonut(bool isDark, List<dynamic> trend) {
    final last7 = trend.length >= 7 ? trend.sublist(trend.length - 7) : trend;
    final labels = last7.map((e) {
      final date = e['date'] as String? ?? '';
      if (date.length >= 10) {
        final parts = date.split('-');
        if (parts.length >= 3) return '${parts[2]}/${parts[1]}';
      }
      return date;
    }).toList();
    final revenues = last7
        .map((e) => (e['revenue'] as num?)?.toDouble() ?? 0)
        .toList();
    final total = revenues.fold(0.0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      AppColors.vividBlue,
      AppColors.caribbeanGreen,
      AppColors.oceanBlue,
      AppColors.lightBlue,
      AppColors.vividBlue,
      AppColors.caribbeanGreen,
      AppColors.oceanBlue,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: List.generate(revenues.length, (i) {
                    final pct = (revenues[i] / total * 100);
                    return PieChartSectionData(
                      value: revenues[i],
                      color: colors[i % colors.length],
                      radius: 40,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(revenues.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${labels[i]}: ${revenues[i].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtNum(dynamic value) {
    if (value == null) return '0';
    final n = value is num ? value : (double.tryParse(value.toString()) ?? 0);
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _fmtCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _OVData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _OVData(this.icon, this.value, this.label, this.color);
}

class _MetricData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _MetricData(this.value, this.label, this.icon, this.color);
}
