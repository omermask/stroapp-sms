import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/affiliate_api.dart';
import '../../../core/api/api_exceptions.dart';

class CommissionsScreen extends ConsumerStatefulWidget {
  const CommissionsScreen({super.key});

  @override
  ConsumerState<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends ConsumerState<CommissionsScreen> {
  List<Map<String, dynamic>> _commissions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _activeFilter;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _perPage = 20;

  final _filters = [
    {'key': null, 'label': 'الكل'},
    {'key': 'pending', 'label': 'معلق'},
    {'key': 'approved', 'label': 'مقبول'},
    {'key': 'paid', 'label': 'مدفوع'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCommissions());
  }

  Future<void> _fetchCommissions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = refresh || _commissions.isEmpty;
      _error = null;
    });

    try {
      final data = await ref.read(affiliateApiProvider).getCommissions(_activeFilter, _currentPage, _perPage);
      final list = (data['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _commissions = list;
          } else {
            _commissions.addAll(list);
          }
          _hasMore = list.length >= _perPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل العمولات');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchCommissions();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onFilterChanged(String? filter) {
    setState(() => _activeFilter = filter);
    _fetchCommissions(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('العمولات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.canvasLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final key = f['key'];
            final label = f['label'] as String;
            final isSelected = _activeFilter == key;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => _onFilterChanged(key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceStrongLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? AppColors.onPrimary : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null && _commissions.isEmpty) {
      return CustomErrorWidget(message: _error!, onRetry: () => _fetchCommissions(refresh: true));
    }

    if (_commissions.isEmpty) {
      return const EmptyState(
        icon: QasehIcons.document_curved,
        message: 'لا توجد عمولات',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchCommissions(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification && notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _commissions.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _commissions.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            return _buildCommissionCard(_commissions[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCommissionCard(Map<String, dynamic> commission) {
    final amount = commission['amount']?.toString() ?? '0';
    final status = commission['status']?.toString() ?? '—';
    final description = commission['description']?.toString() ?? commission['notes']?.toString() ?? '—';
    final date = commission['date']?.toString() ?? commission['created_at']?.toString() ?? '';

    final statusColor = status == 'paid'
        ? AppColors.success
        : (status == 'approved' ? AppColors.bluePrimary : AppColors.warning);
    final statusText = status == 'paid'
        ? 'مدفوع'
        : (status == 'approved' ? 'مقبول' : 'معلق');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == 'paid' ? QasehIcons.tick_square_curved : QasehIcons.time_circle_curved,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                if (date.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTextStyles.numberMedium.copyWith(color: AppColors.success)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
