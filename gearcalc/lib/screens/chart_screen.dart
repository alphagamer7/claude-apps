import 'package:flutter/material.dart';
import '../models/gear_ratio.dart';
import '../widgets/gear_chart.dart';

class ChartScreen extends StatefulWidget {
  final List<GearRatio> ratios;
  final List<int> chainrings;
  final double cadence;
  final bool imperial;
  final List<GearRatio>? comparisonRatios;
  final List<int>? comparisonChainrings;

  const ChartScreen({
    super.key,
    required this.ratios,
    required this.chainrings,
    required this.cadence,
    required this.imperial,
    this.comparisonRatios,
    this.comparisonChainrings,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  ChartViewMode _viewMode = ChartViewMode.ratio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gear Chart'),
        actions: [
          PopupMenuButton<ChartViewMode>(
            icon: const Icon(Icons.tune, color: Color(0xFFCDDC39)),
            color: const Color(0xFF333333),
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder: (_) => [
              _menuItem(ChartViewMode.ratio, 'Gear Ratio'),
              _menuItem(ChartViewMode.speed,
                  widget.imperial ? 'Speed (mph)' : 'Speed (km/h)'),
              _menuItem(ChartViewMode.gearInches, 'Gear Inches'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewModeSelector(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: GearChartWidget(
                ratios: widget.ratios,
                viewMode: _viewMode,
                cadence: widget.cadence,
                imperial: widget.imperial,
                chainrings: widget.chainrings,
                comparisonRatios: widget.comparisonRatios,
              ),
            ),
          ),
          _buildSummary(),
        ],
      ),
    );
  }

  PopupMenuEntry<ChartViewMode> _menuItem(ChartViewMode mode, String label) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          if (_viewMode == mode)
            const Icon(Icons.check, color: Color(0xFFCDDC39), size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _viewChip('Ratio', ChartViewMode.ratio),
          const SizedBox(width: 8),
          _viewChip(
              widget.imperial ? 'Speed (mph)' : 'Speed (km/h)',
              ChartViewMode.speed),
          const SizedBox(width: 8),
          _viewChip('Gear Inches', ChartViewMode.gearInches),
        ],
      ),
    );
  }

  Widget _viewChip(String label, ChartViewMode mode) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCDDC39) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFCDDC39) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final sorted = List<GearRatio>.from(widget.ratios);
    sorted.sort((a, b) => a.ratio.compareTo(b.ratio));

    final lowest = sorted.first;
    final highest = sorted.last;
    final range = highest.ratio / lowest.ratio;
    final overlaps = widget.ratios.where((r) => r.isOverlap).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Lowest', '${lowest.label}\n${lowest.ratio.toStringAsFixed(2)}'),
              _statItem('Highest', '${highest.label}\n${highest.ratio.toStringAsFixed(2)}'),
              _statItem('Range', '${range.toStringAsFixed(0)}%'),
              _statItem('Gears', '${widget.ratios.length}'),
              _statItem('Overlaps', '$overlaps'),
            ],
          ),
          if (widget.comparisonRatios != null) ...[
            const Divider(color: Colors.white12, height: 20),
            const Text('Comparison loaded - shown as faded bars',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Color(0xFFCDDC39),
              fontSize: 13,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
