import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/streak_service.dart';
import '../widgets/stat_card.dart';
import 'active_session_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _appNameController = TextEditingController();
  double _durationMinutes = 25;
  int _currentStreak = 0;
  int _todaySessions = 0;
  int _totalMinutes = 0;

  final DatabaseService _db = DatabaseService();
  final StreakService _streakService = StreakService();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final streak = await _streakService.getCurrentStreak();
    final todayCount = await _db.getTodaySessionCount();
    final totalMin = await _db.getTotalFocusMinutes();
    if (mounted) {
      setState(() {
        _currentStreak = streak;
        _todaySessions = todayCount;
        _totalMinutes = totalMin;
      });
    }
  }

  void _startSession(int durationMinutes) {
    final appName = _appNameController.text.trim();
    if (appName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an app name to focus on'),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(
          appName: appName,
          durationMinutes: durationMinutes,
        ),
      ),
    ).then((_) => _loadStats());
  }

  @override
  void dispose() {
    _appNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'FocusFence',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ).then((_) => _loadStats());
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Today',
                    value: '$_todaySessions',
                    icon: Icons.today,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Streak',
                    value: '$_currentStreak',
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Total min',
                    value: '$_totalMinutes',
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // App name input
            Text(
              'What are you focusing on?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _appNameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g. Xcode, Figma, Writing...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3F51B5)),
                ),
                prefixIcon: Icon(
                  Icons.app_shortcut,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Duration slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade300,
                  ),
                ),
                Text(
                  '${_durationMinutes.round()} minutes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F51B5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF3F51B5),
                inactiveTrackColor: Colors.grey.shade800,
                thumbColor: const Color(0xFF3F51B5),
                overlayColor: const Color(0xFF3F51B5).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _durationMinutes,
                min: 5,
                max: 60,
                divisions: 11,
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Quick start buttons
            Text(
              'Quick start',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final mins in [15, 30, 45]) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: mins != 45 ? 10 : 0),
                      child: OutlinedButton(
                        onPressed: () => _startSession(mins),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3F51B5),
                          side: const BorderSide(color: Color(0xFF3F51B5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '$mins min',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // Main start button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _startSession(_durationMinutes.round()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Focus Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Motivational footer
            Center(
              child: Text(
                'Finish what you start.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
