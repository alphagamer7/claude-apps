import 'package:flutter/material.dart';
import '../models/gear_ratio.dart';

enum TableDisplayMode { ratio, speed, gearInches, development }

class RatioTable extends StatelessWidget {
  final List<GearRatio> ratios;
  final List<int> chainrings;
  final List<int> cassette;
  final TableDisplayMode displayMode;
  final double cadence;
  final bool imperial;

  const RatioTable({
    super.key,
    required this.ratios,
    required this.chainrings,
    required this.cassette,
    required this.displayMode,
    required this.cadence,
    required this.imperial,
  });

  static const List<Color> chainringColors = [
    Color(0xFFCDDC39),
    Color(0xFF29B6F6),
    Color(0xFFEF5350),
  ];

  GearRatio? _findRatio(int chainring, int cog) {
    for (final r in ratios) {
      if (r.chainring == chainring && r.cog == cog) return r;
    }
    return null;
  }

  String _formatValue(GearRatio gr) {
    switch (displayMode) {
      case TableDisplayMode.ratio:
        return gr.ratio.toStringAsFixed(2);
      case TableDisplayMode.speed:
        return gr
            .speedAtCadence(cadence, imperial: imperial)
            .toStringAsFixed(1);
      case TableDisplayMode.gearInches:
        return gr.gearInches.toStringAsFixed(1);
      case TableDisplayMode.development:
        return gr.developmentMeters.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (chainrings.isEmpty || cassette.isEmpty) {
      return const Center(
        child: Text('Enter chainrings and cassette values',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          headingTextStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          border: TableBorder.all(
            color: Colors.white10,
            width: 0.5,
            borderRadius: BorderRadius.circular(4),
          ),
          columns: [
            const DataColumn(
              label: Text('Cog', style: TextStyle(color: Colors.white54)),
            ),
            for (int i = 0; i < chainrings.length; i++)
              DataColumn(
                label: Text(
                  '${chainrings[i]}T',
                  style: TextStyle(
                    color: chainringColors[i % chainringColors.length],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
          rows: cassette.map((cog) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${cog}T',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                for (int i = 0; i < chainrings.length; i++)
                  _buildCell(chainrings[i], cog, i),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DataCell _buildCell(int chainring, int cog, int colorIndex) {
    final gr = _findRatio(chainring, cog);
    if (gr == null) {
      return const DataCell(Text('-', style: TextStyle(color: Colors.white24)));
    }

    final bgColor = gr.isOverlap
        ? const Color(0x30FF9800)
        : Colors.transparent;

    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatValue(gr),
          style: TextStyle(
            color: gr.isOverlap
                ? Colors.orangeAccent
                : chainringColors[colorIndex % chainringColors.length]
                    .withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: gr.isOverlap ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
