import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/affiliate_api.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/models/affiliate_summary.dart';

class AffiliateDashboardScreen extends ConsumerStatefulWidget {
  const AffiliateDashboardScreen({super.key});

  @override
  ConsumerState<AffiliateDashboardScreen> createState() => _AffiliateDashboardScreenState();
}

class _AffiliateDashboardScreenState extends ConsumerState<AffiliateDashboardScreen> {
  AffiliateSummary? _summary;
  List<dynamic> _commissions = [];
  List<dynamic> _revenueShare = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(affiliateApiProvider);
      final summaryData = await api.getSummary();
      final summary = AffiliateSummary.fromJson(summaryData);

      final commissionsData = await api.getCommissions(null, 1, 5);
      final commissionsList = (commissionsData['data'] as List<dynamic>?) ?? (commissionsData['commissions'] as List<dynamic>?) ?? [];

      final revenueData = await api.getRevenueShare(1, 5);
      final revenueList = (revenueData['data'] as List<dynamic>?) ?? (revenueData['revenue_share'] as List<dynamic>?) ?? [];

      if (mounted) {
        setState(() {
          _summary = summary;
          _commissions = commissionsList;
          _revenueShare = revenueList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = extractErrorMessage(e, fallback: 'حدث خطأ في تحميل البيانات');
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
        title: const Text('لوحة التسويق'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
        actions: [
          TextButton(
            onPressed: () => context.push('/affiliate/apply'),
            child: Text('التسجيل', style: AppTextStyles.labelMedium.copyWith(color: AppColors.bluePrimary)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return CustomErrorWidget(message: _error!, onRetry: _fetchData);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionHeader('آخر العمولات', () => context.push('/affiliate/commissions')),
            const SizedBox(height: 12),
            if (_commissions.isEmpty)
              _buildEmptyCard('لا توجد عمولات بعد')
            else
              ...(_commissions.take(5).map((c) => _buildCommissionItem(c))),
            const SizedBox(height: 24),
            _buildSectionHeader('حصة الإيرادات', null),
            const SizedBox(height: 12),
            if (_revenueShare.isEmpty)
              _buildEmptyCard('لا توجد حصة إيرادات بعد')
            else
              ...(_revenueShare.take(5).map((r) => _buildRevenueItem(r))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalEarned = _summary?.totalEarned ?? 0;
    final pending = _summary?.pending ?? 0;
    final paid = _summary?.paid ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard('الإجمالي', totalEarned.toStringAsFixed(2), AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('معلق', pending.toStringAsFixed(2), AppColors.warning),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('مدفوع', paid.toStringAsFixed(2), AppColors.success),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        children: [
          Text(amount, style: AppTextStyles.numberLarge.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(QasehIcons.ticket_star_curved, size: 24, color: AppColors.bluePrimary),
                const SizedBox(height: 8),
                Text('${_commissions.length}', style: AppTextStyles.numberMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('العمولات', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.hairlineLight),
          Expanded(
            child: Column(
              children: [
                Icon(QasehIcons.activity_curved, size: 24, color: AppColors.bluePrimary),
                const SizedBox(height: 8),
                Text('${_revenueShare.length}', style: AppTextStyles.numberMedium.copyWith(color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('حصة الإيرادات', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onViewAll) {
    return Row(
      children: [
        Icon(QasehIcons.document_curved, size: 18, color: AppColors.ink),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text('عرض الكل', style: AppTextStyles.labelSmall.copyWith(color: AppColors.bluePrimary)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.bluePrimary),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCommissionItem(dynamic c) {
    final amount = c['amount']?.toString() ?? '0';
    final status = c['status']?.toString() ?? '—';
    final description = c['description']?.toString() ?? c['notes']?.toString() ?? '—';
    final date = c['date']?.toString() ?? c['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Row(
        children: [
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
          Text(amount, style: AppTextStyles.numberMedium.copyWith(color: AppColors.success)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(dynamic r) {
    final amount = r['amount']?.toString() ?? '0';
    final date = r['date']?.toString() ?? r['created_at']?.toString() ?? '';
    final level = r['level']?.toString() ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المستوى: $level', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                if (date.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                  ),
              ],
            ),
          ),
          Text(amount, style: AppTextStyles.numberMedium.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        children: [
          Icon(QasehIcons.document_curved, size: 32, color: AppColors.mutedStrong),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
        ],
      ),
    );
  }
}
