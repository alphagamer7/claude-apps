import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cost_calculator.dart';
import '../services/storage_service.dart';
import '../widgets/preset_chip.dart';
import 'meeting_screen.dart';
import 'history_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _attendeeCount = 5;
  final _rateController = TextEditingController(text: '75.00');
  final _storage = StorageService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final rate = await _storage.getDefaultRate();
    final attendees = await _storage.getDefaultAttendees();
    setState(() {
      _attendeeCount = attendees;
      _rateController.text = rate.toStringAsFixed(2);
      _isLoading = false;
    });
  }

  double get _hourlyRate =>
      double.tryParse(_rateController.text) ?? 0;

  double get _costPerSecond {
    final calc = CostCalculator(
      attendeeCount: _attendeeCount,
      hourlyRate: _hourlyRate,
    );
    return calc.costPerSecond;
  }

  void _setAttendees(int count) {
    setState(() {
      _attendeeCount = count.clamp(1, 100);
    });
  }

  void _applyPreset(int attendees) {
    setState(() {
      _attendeeCount = attendees;
    });
  }

  Future<void> _startMeeting() async {
    if (_hourlyRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid hourly rate')),
      );
      return;
    }

    // Save defaults for next time
    await _storage.saveDefaultRate(_hourlyRate);
    await _storage.saveDefaultAttendees(_attendeeCount);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeetingScreen(
          attendeeCount: _attendeeCount,
          hourlyRate: _hourlyRate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeetingCost'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            tooltip: 'Meeting History',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'How much is this\nmeeting costing?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Quick Presets
            const Text(
              'Quick Presets',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PresetChip(
                  label: 'Standup (5)',
                  onTap: () => _applyPreset(5),
                ),
                PresetChip(
                  label: 'Team Meeting (10)',
                  onTap: () => _applyPreset(10),
                ),
                PresetChip(
                  label: 'All-Hands (25)',
                  onTap: () => _applyPreset(25),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Attendee Count
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Number of Attendees',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircleButton(
                        Icons.remove,
                        () => _setAttendees(_attendeeCount - 1),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '$_attendeeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildCircleButton(
                        Icons.add,
                        () => _setAttendees(_attendeeCount + 1),
                      ),
                    ],
                  ),
                  Text(
                    _attendeeCount == 1 ? 'person' : 'people',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hourly Rate
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Average Hourly Rate',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RobotoMono',
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'per person / hour',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cost Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.speed, color: Color(0xFFFF5722), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Cost preview: \$${_costPerSecond.toStringAsFixed(3)}/sec  '
                    '(\$${(_costPerSecond * 60).toStringAsFixed(2)}/min)',
                    style: const TextStyle(
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Start Meeting Button
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _startMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFF5722).withValues(alpha: 0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Meeting',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFFF5722).withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: const Color(0xFFFF5722), size: 28),
        ),
      ),
    );
  }
}
