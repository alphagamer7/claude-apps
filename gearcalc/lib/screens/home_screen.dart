import 'package:flutter/material.dart';
import '../models/drivetrain.dart';
import '../models/gear_ratio.dart';
import '../services/gear_calculator.dart';
import '../services/storage_service.dart';
import '../widgets/ratio_table.dart';
import 'chart_screen.dart';
import 'saved_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chainringController = TextEditingController(text: '50, 34');
  final _cassetteController =
      TextEditingController(text: '11,12,13,14,15,17,19,21,24,28');
  final _cadenceController = TextEditingController(text: '90');
  final _nameController = TextEditingController();

  String _selectedWheelSize = '700c';
  double _customWheelCircumference = 2100;
  bool _imperial = false;

  List<int> _chainrings = [50, 34];
  List<int> _cassette = [11, 12, 13, 14, 15, 17, 19, 21, 24, 28];
  double _cadence = 90;
  List<GearRatio> _ratios = [];
  TableDisplayMode _tableMode = TableDisplayMode.ratio;

  Drivetrain? _comparisonSetup;

  @override
  void initState() {
    super.initState();
    _calculate();
    _chainringController.addListener(_onInputChanged);
    _cassetteController.addListener(_onInputChanged);
    _cadenceController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _chainringController.dispose();
    _cassetteController.dispose();
    _cadenceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _parseInputs();
    _calculate();
  }

  void _parseInputs() {
    final chainringText = _chainringController.text.trim();
    final cassetteText = _cassetteController.text.trim();
    final cadenceText = _cadenceController.text.trim();

    _chainrings = _parseIntList(chainringText);
    _cassette = _parseIntList(cassetteText);
    _cadence = double.tryParse(cadenceText) ?? 90;
  }

  List<int> _parseIntList(String text) {
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r'[,\s]+'))
        .map((s) => int.tryParse(s.trim()))
        .where((v) => v != null && v > 0)
        .cast<int>()
        .toList();
  }

  double _getWheelCircumference() {
    if (_selectedWheelSize == 'Custom') {
      return _customWheelCircumference;
    }
    final ws = WheelSize.fromName(_selectedWheelSize);
    return ws?.circumferenceMm ?? 2100;
  }

  void _calculate() {
    if (_chainrings.isEmpty || _cassette.isEmpty) {
      setState(() => _ratios = []);
      return;
    }

    final dt = _buildDrivetrain('temp', 'Temp');
    setState(() {
      _ratios = GearCalculator.calculateAll(dt);
    });
  }

  Drivetrain _buildDrivetrain(String id, String name) {
    return Drivetrain(
      id: id,
      name: name,
      chainrings: List.from(_chainrings),
      cassette: List.from(_cassette),
      wheelCircumferenceMm: _getWheelCircumference(),
      wheelSizeName: _selectedWheelSize,
    );
  }

  void _loadPreset(Drivetrain preset) {
    _chainringController.text = preset.chainrings.join(', ');
    _cassetteController.text = preset.cassette.join(',');
    _selectedWheelSize = preset.wheelSizeName;
    _parseInputs();
    _calculate();
  }

  void _loadSetup(Drivetrain dt) {
    _chainringController.text = dt.chainrings.join(', ');
    _cassetteController.text = dt.cassette.join(',');
    _selectedWheelSize = dt.wheelSizeName;
    _parseInputs();
    _calculate();
  }

  Future<void> _saveSetup() async {
    if (_chainrings.isEmpty || _cassette.isEmpty) {
      _showSnackBar('Enter chainrings and cassette first');
      return;
    }

    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dt = _buildDrivetrain(id, name);
    await StorageService.save(dt);
    _showSnackBar('Setup "$name" saved');
  }

  Future<String?> _showNameDialog() {
    _nameController.clear();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Save Setup', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Setup name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCDDC39)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _nameController.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: Color(0xFFCDDC39))),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openChart() {
    if (_ratios.isEmpty) {
      _showSnackBar('Calculate gear ratios first');
      return;
    }
    List<GearRatio>? compRatios;
    if (_comparisonSetup != null) {
      compRatios = GearCalculator.calculateAll(_comparisonSetup!);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartScreen(
          ratios: _ratios,
          chainrings: _chainrings,
          cadence: _cadence,
          imperial: _imperial,
          comparisonRatios: compRatios,
          comparisonChainrings: _comparisonSetup?.chainrings,
        ),
      ),
    );
  }

  Future<void> _openSaved() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SavedScreen()),
    );
    if (result != null) {
      if (result.containsKey('load')) {
        _loadSetup(result['load'] as Drivetrain);
      }
      if (result.containsKey('compare')) {
        setState(() {
          _comparisonSetup = result['compare'] as Drivetrain;
        });
        _showSnackBar('Comparison setup loaded');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GearCalc'),
        actions: [
          IconButton(
            icon: Icon(
              _imperial ? Icons.speed : Icons.speed_outlined,
              color: const Color(0xFFCDDC39),
            ),
            tooltip: _imperial ? 'Switch to metric' : 'Switch to imperial',
            onPressed: () {
              setState(() => _imperial = !_imperial);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFFCDDC39)),
            tooltip: 'View Chart',
            onPressed: _openChart,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPresetsRow(),
            const SizedBox(height: 16),
            _buildInputSection(),
            const SizedBox(height: 12),
            _buildActionButtons(),
            if (_comparisonSetup != null) ...[
              const SizedBox(height: 8),
              _buildComparisonBanner(),
            ],
            const SizedBox(height: 16),
            _buildTableModeSelector(),
            const SizedBox(height: 8),
            _buildOverlapInfo(),
            const SizedBox(height: 8),
            SizedBox(
              height: 400,
              child: RatioTable(
                ratios: _ratios,
                chainrings: _chainrings,
                cassette: _cassette,
                displayMode: _tableMode,
                cadence: _cadence,
                imperial: _imperial,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 8),
            child: Text('Presets:',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          for (final preset in Drivetrain.presets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(preset.name,
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: const Color(0xFF2A2A2A),
                side: const BorderSide(color: Colors.white12),
                onPressed: () => _loadPreset(preset),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Drivetrain Setup',
                style: TextStyle(
                    color: Color(0xFFCDDC39),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _chainringController,
              label: 'Chainrings (e.g. 50, 34)',
              icon: Icons.rotate_right,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _cassetteController,
              label: 'Cassette (e.g. 11,13,15,17,19,21,24,28,32)',
              icon: Icons.rotate_left,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildWheelDropdown(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _cadenceController,
                    label: 'Cadence (RPM)',
                    icon: Icons.timer,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (_selectedWheelSize == 'Custom') ...[
              const SizedBox(height: 10),
              _buildCustomWheelInput(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFCDDC39), size: 20),
        filled: true,
        fillColor: const Color(0xFF252525),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCDDC39)),
        ),
      ),
    );
  }

  Widget _buildWheelDropdown() {
    final items = [
      ...WheelSize.presets.map((ws) => ws.name),
      'Custom',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWheelSize,
          isExpanded: true,
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFCDDC39)),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedWheelSize = val;
              });
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildCustomWheelInput() {
    return Row(
      children: [
        const Text('Circumference (mm): ',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        Expanded(
          child: Slider(
            value: _customWheelCircumference,
            min: 1500,
            max: 2500,
            divisions: 100,
            activeColor: const Color(0xFFCDDC39),
            inactiveColor: Colors.white12,
            label: '${_customWheelCircumference.round()} mm',
            onChanged: (val) {
              setState(() {
                _customWheelCircumference = val;
              });
              _calculate();
            },
          ),
        ),
        Text('${_customWheelCircumference.round()} mm',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _openChart,
          icon: const Icon(Icons.bar_chart, size: 18),
          label: const Text('View Chart'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCDDC39),
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _saveSetup,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Save Setup'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFCDDC39),
            side: const BorderSide(color: Color(0xFFCDDC39)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _openSaved,
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('Load / Compare'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3D00),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCDDC39), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows,
              color: Color(0xFFCDDC39), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Comparing with: ${_comparisonSetup!.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _comparisonSetup = null),
            child: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTableModeSelector() {
    return Row(
      children: [
        const Text('Show: ',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 8),
        _modeChip('Ratio', TableDisplayMode.ratio),
        const SizedBox(width: 6),
        _modeChip(
            _imperial ? 'mph' : 'km/h', TableDisplayMode.speed),
        const SizedBox(width: 6),
        _modeChip('Gear"', TableDisplayMode.gearInches),
        const SizedBox(width: 6),
        _modeChip('Dev (m)', TableDisplayMode.development),
      ],
    );
  }

  Widget _modeChip(String label, TableDisplayMode mode) {
    final selected = _tableMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _tableMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCDDC39) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlapInfo() {
    if (_chainrings.length < 2 || _ratios.isEmpty) return const SizedBox();

    final overlaps = GearCalculator.findOverlapPairs(_ratios);
    if (overlaps.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F00),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 16),
              SizedBox(width: 6),
              Text('Gear Overlap',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ...overlaps.take(5).map((pair) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${pair.a.label} ~ ${pair.b.label} '
                  '(${pair.percentDiff.toStringAsFixed(1)}% diff)',
                  style: const TextStyle(
                      color: Colors.orangeAccent, fontSize: 11),
                ),
              )),
          if (overlaps.length > 5)
            Text(
              '  ...and ${overlaps.length - 5} more',
              style:
                  const TextStyle(color: Colors.orange, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
