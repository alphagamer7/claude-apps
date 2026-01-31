import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/gear_ratio.dart';

enum ChartViewMode { ratio, speed, gearInches }

class GearChartWidget extends StatelessWidget {
  final List<GearRatio> ratios;
  final ChartViewMode viewMode;
  final double cadence;
  final bool imperial;
  final List<GearRatio>? comparisonRatios;
  final List<int> chainrings;

  const GearChartWidget({
    super.key,
    required this.ratios,
    required this.viewMode,
    required this.cadence,
    required this.imperial,
    required this.chainrings,
    this.comparisonRatios,
  });

  static const List<Color> chainringColors = [
    Color(0xFFCDDC39), // lime
    Color(0xFF29B6F6), // light blue
    Color(0xFFEF5350), // red
  ];

  static const List<Color> comparisonColors = [
    Color(0x80CDDC39), // lime faded
    Color(0x8029B6F6), // light blue faded
    Color(0x80EF5350), // red faded
  ];

  double _getValue(GearRatio gr) {
    switch (viewMode) {
      case ChartViewMode.ratio:
        return gr.ratio;
      case ChartViewMode.speed:
        return gr.speedAtCadence(cadence, imperial: imperial);
      case ChartViewMode.gearInches:
        return gr.gearInches;
    }
  }

  String _getYLabel() {
    switch (viewMode) {
      case ChartViewMode.ratio:
        return 'Gear Ratio';
      case ChartViewMode.speed:
        return imperial ? 'Speed (mph)' : 'Speed (km/h)';
      case ChartViewMode.gearInches:
        return 'Gear Inches';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ratios.isEmpty) {
      return const Center(
        child: Text('No gear data to display',
            style: TextStyle(color: Colors.white70)),
      );
    }

    // Sort ratios by value for display
    final sorted = List<GearRatio>.from(ratios);
    sorted.sort((a, b) => _getValue(a).compareTo(_getValue(b)));

    List<GearRatio>? sortedComparison;
    if (comparisonRatios != null && comparisonRatios!.isNotEmpty) {
      sortedComparison = List<GearRatio>.from(comparisonRatios!);
      sortedComparison.sort((a, b) => _getValue(a).compareTo(_getValue(b)));
    }

    final maxVal = _findMaxValue(sorted, sortedComparison);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            _getYLabel(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final gear = sorted[groupIndex];
                      final value = _getValue(gear);
                      return BarTooltipItem(
                        '${gear.label}\n${value.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every Nth label to avoid crowding
                        final step = (sorted.length / 12).ceil().clamp(1, 10);
                        if (idx % step != 0 && idx != sorted.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              sorted[idx].label,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: _buildBarGroups(sorted, sortedComparison),
              ),
            ),
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  double _findMaxValue(
      List<GearRatio> sorted, List<GearRatio>? sortedComparison) {
    double max = sorted.map(_getValue).reduce((a, b) => a > b ? a : b);
    if (sortedComparison != null && sortedComparison.isNotEmpty) {
      final compMax =
          sortedComparison.map(_getValue).reduce((a, b) => a > b ? a : b);
      if (compMax > max) max = compMax;
    }
    return max;
  }

  List<BarChartGroupData> _buildBarGroups(
      List<GearRatio> sorted, List<GearRatio>? sortedComparison) {
    return List.generate(sorted.length, (index) {
      final gear = sorted[index];
      final colorIndex = chainrings.indexOf(gear.chainring) % chainringColors.length;
      final color = gear.isOverlap
          ? chainringColors[colorIndex].withValues(alpha: 0.5)
          : chainringColors[colorIndex];

      final rods = <BarChartRodData>[
        BarChartRodData(
          toY: _getValue(gear),
          color: color,
          width: sortedComparison != null ? 6 : 10,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
          ),
          borderSide: gear.isOverlap
              ? const BorderSide(color: Colors.orangeAccent, width: 1)
              : BorderSide.none,
        ),
      ];

      // Add comparison bar if available
      if (sortedComparison != null && index < sortedComparison.length) {
        final compGear = sortedComparison[index];
        rods.add(BarChartRodData(
          toY: _getValue(compGear),
          color: Colors.white30,
          width: 6,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
          ),
        ));
      }

      return BarChartGroupData(
        x: index,
        barRods: rods,
      );
    });
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          for (int i = 0; i < chainrings.length; i++)
            _legendItem(
              '${chainrings[i]}T',
              chainringColors[i % chainringColors.length],
            ),
          _legendItem('Overlap', Colors.orangeAccent, hasBorder: true),
          if (comparisonRatios != null)
            _legendItem('Comparison', Colors.white30),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: hasBorder
                ? Border.all(color: Colors.orangeAccent, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
