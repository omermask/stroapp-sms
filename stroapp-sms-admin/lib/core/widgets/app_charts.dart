import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ──────────────────────────────────────────────
// Bar Chart – Income (green) & Expense (blue) bars
// Used: Analysis / Daily / Weekly / Monthly / Yearly
// ──────────────────────────────────────────────
class AppBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> incomeValues;
  final List<double> expenseValues;
  final double maxValue;
  final double barWidth;
  final double barRadius;

  const AppBarChart({
    super.key,
    required this.labels,
    required this.incomeValues,
    required this.expenseValues,
    this.maxValue = 15000,
    this.barWidth = 12,
    this.barRadius = 31,
  });

  factory AppBarChart.weekly() {
    return const AppBarChart(
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      incomeValues: [4000, 6000, 3000, 8000, 5000, 7000, 4000],
      expenseValues: [2000, 3000, 1500, 4000, 2500, 3500, 2000],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _legendDot(AppColors.caribbeanGreen, 'Income'),
            const SizedBox(width: 16),
            _legendDot(AppColors.oceanBlue, 'Expense'),
          ],
        ),
        const SizedBox(height: 16),
        // Y-axis labels + bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y-axis
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _yLabel('15k'),
                _yLabel('10k'),
                _yLabel('5k'),
                _yLabel('1k'),
                const SizedBox(height: 4),
              ],
            ),
            const SizedBox(width: 8),
            // Bars
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(labels.length, (i) {
                  return _BarColumn(
                    label: labels[i],
                    incomeHeight: (incomeValues[i] / maxValue) * 140,
                    expenseHeight: (expenseValues[i] / maxValue) * 140,
                    barWidth: barWidth,
                    barRadius: barRadius,
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.chartLabel.copyWith(color: AppColors.cyprus),
        ),
      ],
    );
  }

  Widget _yLabel(String text) {
    return Text(
      text,
      style: AppTypography.chartLabel.copyWith(
        color: AppColors.lightBlue,
        fontSize: 14,
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String label;
  final double incomeHeight;
  final double expenseHeight;
  final double barWidth;
  final double barRadius;

  const _BarColumn({
    required this.label,
    required this.incomeHeight,
    required this.expenseHeight,
    required this.barWidth,
    required this.barRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stacked bars (income behind, expense in front)
        SizedBox(
          width: barWidth * 2 + 4,
          height: 140,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Income bar (green, behind)
              if (incomeHeight > 0)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: barWidth,
                    height: incomeHeight,
                    decoration: BoxDecoration(
                      color: AppColors.caribbeanGreen,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(barRadius),
                        topRight: Radius.circular(barRadius),
                      ),
                    ),
                  ),
                ),
              // Expense bar (blue, in front)
              if (expenseHeight > 0)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: barWidth,
                    height: expenseHeight,
                    decoration: BoxDecoration(
                      color: AppColors.oceanBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(barRadius),
                        topRight: Radius.circular(barRadius),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.chartLabel.copyWith(
            color: AppColors.cyprus,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Donut / Pie Chart – category breakdown
// Used: Analysis screen
// ──────────────────────────────────────────────
class DonutSlice {
  final String label;
  final double percentage;
  final Color color;
  DonutSlice({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

class AppDonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;

  const AppDonutChart({
    super.key,
    required this.slices,
    this.size = 120,
    this.strokeWidth = 24,
  });

  factory AppDonutChart.sample() {
    return AppDonutChart(
      slices: [
        DonutSlice(
          label: 'Food',
          percentage: 0.30,
          color: AppColors.caribbeanGreen,
        ),
        DonutSlice(
          label: 'Transport',
          percentage: 0.25,
          color: AppColors.oceanBlue,
        ),
        DonutSlice(
          label: 'Groceries',
          percentage: 0.20,
          color: AppColors.vividBlue,
        ),
        DonutSlice(
          label: 'Others',
          percentage: 0.15,
          color: AppColors.lightBlue,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(slices: slices, strokeWidth: strokeWidth),
          ),
          // Center total
          Text(
            '${(slices.fold<double>(0, (sum, s) => sum + s.percentage) * 100).round()}%',
            style: AppTypography.chartValue.copyWith(
              fontSize: 16,
              color: AppColors.cyprus,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double strokeWidth;

  _DonutPainter({required this.slices, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    double startAngle = -0.5 * 3.1415927; // start from top

    for (final slice in slices) {
      final sweepAngle = slice.percentage * 2 * 3.1415927;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

// ──────────────────────────────────────────────
// Donut Chart Legend
// ──────────────────────────────────────────────
class AppDonutLegend extends StatelessWidget {
  final List<DonutSlice> slices;

  const AppDonutLegend({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: slices.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${s.label}  ${(s.percentage * 100).round()}%',
                style: AppTypography.categoryLabel.copyWith(
                  color: AppColors.cyprus,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
