import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/money.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// White cumulative-spend line for the blue hero: this month solid with a
/// soft fill, last month as a faint dashed line to beat.
class HeroTrendChart extends StatelessWidget {
  const HeroTrendChart({super.key, required this.daily, required this.previous, required this.month, this.height = 150});

  final List<int> daily;
  final List<int> previous;
  final DateTime month;
  final double height;

  @override
  Widget build(BuildContext context) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final maxY = math.max(1, [...daily, ...previous].fold<int>(0, math.max)) * 1.12;
    List<FlSpot> spots(List<int> v) => [for (var i = 0; i < v.length; i++) FlSpot(i + 1.0, v[i] / 100)];
    return SizedBox(
      height: height,
      child: LineChart(
        duration: Motion.of(context, Motion.page),
        curve: Motion.signature,
        LineChartData(
          minX: 1,
          maxX: days.toDouble(),
          minY: 0,
          maxY: maxY / 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (bar, idx) => [
              for (final _ in idx)
                TouchedSpotIndicatorData(
                  FlLine(color: Colors.white.withAlpha(90), strokeWidth: 1, dashArray: [3, 3]),
                  FlDotData(
                    getDotPainter: (_, _, _, _) =>
                        FlDotCirclePainter(radius: 5, color: Colors.white, strokeWidth: 3, strokeColor: Brand.mid),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xe6050f33),
              tooltipBorderRadius: BorderRadius.circular(12),
              fitInsideHorizontally: true,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  s.barIndex == 0
                      ? LineTooltipItem(
                          '${s.x.toInt()} ${DateFormat.MMM().format(month)}\n',
                          TextStyle(color: Colors.white.withAlpha(170), fontSize: 11),
                          children: [
                            TextSpan(
                              text: formatPaise((s.y * 100).round(), decimals: false),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        )
                      : null,
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots(daily),
              isCurved: true,
              preventCurveOverShooting: true,
              color: Colors.white,
              barWidth: 2.6,
              isStrokeCapRound: true,
              dotData: FlDotData(
                checkToShowDot: (s, bar) => s.x == bar.spots.last.x,
                getDotPainter: (_, _, _, _) =>
                    FlDotCirclePainter(radius: 4.5, color: Colors.white, strokeWidth: 3, strokeColor: Brand.blue.withAlpha(150)),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withAlpha(70), Colors.white.withAlpha(0)],
                ),
              ),
            ),
            LineChartBarData(
              spots: spots(previous),
              isCurved: true,
              preventCurveOverShooting: true,
              color: Colors.white.withAlpha(90),
              barWidth: 1.6,
              dashArray: [4, 5],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spending by category as a donut, with the total in the middle.
class CategoryDonut extends StatefulWidget {
  const CategoryDonut({super.key, required this.slices, required this.total});
  final List<(String, int)> slices;
  final int total;

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final touched = _touched == null || _touched! >= widget.slices.length ? null : widget.slices[_touched!];
    return SizedBox(
      height: 210,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(
          duration: Motion.of(context, Motion.page),
          curve: Motion.signature,
          PieChartData(
            centerSpaceRadius: 68,
            sectionsSpace: 2.5,
            startDegreeOffset: -90,
            pieTouchData: PieTouchData(touchCallback: (e, r) {
              if (!e.isInterestedForInteractions || r?.touchedSection == null) {
                if (_touched != null) setState(() => _touched = null);
                return;
              }
              setState(() => _touched = r!.touchedSection!.touchedSectionIndex);
            }),
            sections: [
              for (var i = 0; i < widget.slices.length; i++)
                PieChartSectionData(
                  value: widget.slices[i].$2.toDouble(),
                  color: CategoryVisuals.color(widget.slices[i].$1),
                  radius: i == _touched ? 30 : 24,
                  showTitle: false,
                ),
            ],
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(touched?.$1 ?? 'Spent', style: KText.caption(context)),
          const SizedBox(height: 4),
          MoneyText(touched?.$2 ?? widget.total, style: KText.amount(context, size: 22), decimals: false),
          if (touched != null && widget.total > 0)
            Text('${(touched.$2 * 100 / widget.total).round()}%', style: KText.caption(context).copyWith(color: k.tertiaryLabel)),
        ]),
      ]),
    );
  }
}

/// Six months of totals as rounded bars; the selected month is brand-filled.
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({super.key, required this.months, required this.selected});
  final List<(DateTime, int)> months;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final maxY = math.max(1, months.fold<int>(0, (m, e) => math.max(m, e.$2))) / 100 * 1.15;
    return SizedBox(
      height: 170,
      child: BarChart(
        duration: Motion.of(context, Motion.page),
        curve: Motion.signature,
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (_) => FlLine(color: k.separator, strokeWidth: 1, dashArray: [3, 4]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(DateFormat.MMM().format(months[v.toInt()].$1),
                      style: KText.caption(context).copyWith(fontSize: 12)),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.isDark ? k.surfaceRaised : const Color(0xff1c1c22),
              tooltipBorderRadius: BorderRadius.circular(10),
              getTooltipItem: (g, _, rod, _) => BarTooltipItem(
                formatPaise((rod.toY * 100).round(), decimals: false),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: months[i].$2 / 100,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  gradient: months[i].$1 == selected
                      ? const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Brand.blue, Brand.violet])
                      : null,
                  color: months[i].$1 == selected ? null : (context.isDark ? const Color(0xff2a2f45) : const Color(0xffd9def0)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
