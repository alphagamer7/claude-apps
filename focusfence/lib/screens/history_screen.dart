import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../services/database_service.dart';
import '../services/streak_service.dart';
import '../widgets/session_tile.dart';
import '../widgets/stat_card.dart';

enum SessionFilter { all, completed, abandoned }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final StreakService _streakService = StreakService();

  List<FocusSession> _sessions = [];
  SessionFilter _filter = SessionFilter.all;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _weeklyCount = 0;
  int _weeklyMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _loadFilteredSessions();
    final currentStreak = await _streakService.getCurrentStreak();
    final bestStreak = await _streakService.getBestStreak();
    final weeklyCount = await _streakService.getWeeklySessionCount();
    final weeklyMinutes = await _streakService.getWeeklyFocusMinutes();

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _currentStreak = currentStreak;
        _bestStreak = bestStreak;
        _weeklyCount = weeklyCount;
        _weeklyMinutes = weeklyMinutes;
      });
    }
  }

  Future<List<FocusSession>> _loadFilteredSessions() async {
    switch (_filter) {
      case SessionFilter.all:
        return _db.getAllSessions();
      case SessionFilter.completed:
        return _db.getCompletedSessions();
      case SessionFilter.abandoned:
        return _db.getAbandonedSessions();
    }
  }

  void _setFilter(SessionFilter filter) {
    setState(() {
      _filter = filter;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Current\nStreak',
                    value: '$_currentStreak',
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Best\nStreak',
                    value: '$_bestStreak',
                    icon: Icons.emoji_events,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'This Week\nSessions',
                    value: '$_weeklyCount',
                    icon: Icons.date_range,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Weekly\nMinutes',
                    value: '$_weeklyMinutes',
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', SessionFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', SessionFilter.completed),
                const SizedBox(width: 8),
                _buildFilterChip('Abandoned', SessionFilter.abandoned),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Session list
          Expanded(
            child: _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sessions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your first focus session!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _sessions.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      return SessionTile(session: _sessions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SessionFilter filter) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => _setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3F51B5)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3F51B5)
                : Colors.grey.shade800,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
