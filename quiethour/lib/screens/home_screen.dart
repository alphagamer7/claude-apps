import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quiet_profile.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';
import '../widgets/profile_card.dart';
import 'profile_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notifService = NotificationService();
  final SchedulerService _schedulerService = SchedulerService();

  List<QuietProfile> _profiles = [];
  bool _isLoading = true;
  DateTime? _quickActivateEnd;
  Timer? _quickActivateTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quickActivateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profiles = await _dbService.getAllProfiles();
    final quickEnd = await _notifService.getQuickActivateEnd();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _quickActivateEnd = quickEnd;
      _isLoading = false;
    });
    _startQuickActivateTimerIfNeeded();
  }

  void _startQuickActivateTimerIfNeeded() {
    _quickActivateTimer?.cancel();
    if (_quickActivateEnd != null) {
      _quickActivateTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted) return;
          if (_quickActivateEnd != null &&
              DateTime.now().isAfter(_quickActivateEnd!)) {
            setState(() => _quickActivateEnd = null);
            _notifService.clearQuickActivate();
            _notifService.showQuickActivateEnded();
            _quickActivateTimer?.cancel();
          } else {
            setState(() {}); // Refresh countdown
          }
        },
      );
    }
  }

  Future<void> _toggleProfile(QuietProfile profile, bool enabled) async {
    await _dbService.toggleProfile(profile.id!, enabled);
    await _loadData();
    await _schedulerService.schedulePeriodicCheck();
  }

  Future<void> _startQuickActivate() async {
    final duration = const Duration(minutes: 30);
    final endTime = DateTime.now().add(duration);

    await _notifService.setQuickActivateEnd(endTime);
    await _notifService.showQuickActivateStarted(30);
    await _schedulerService.scheduleQuickActivateEnd(duration);

    setState(() => _quickActivateEnd = endTime);
    _startQuickActivateTimerIfNeeded();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quick quiet mode activated for 30 minutes'),
          backgroundColor: const Color(0xFF7C4DFF),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _cancelQuickActivate() async {
    await _notifService.clearQuickActivate();
    await _notifService.cancelAll();
    await _schedulerService.cancelQuickActivateEnd();
    setState(() => _quickActivateEnd = null);
    _quickActivateTimer?.cancel();
  }

  void _openProfileEditor([QuietProfile? profile]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditorScreen(profile: profile),
      ),
    );
    if (result == true) {
      await _loadData();
      await _schedulerService.schedulePeriodicCheck();
    }
  }

  String _getNextScheduleInfo() {
    DateTime? earliest;
    String? profileName;

    for (final profile in _profiles) {
      if (!profile.isEnabled) continue;
      final next = profile.nextScheduledTime;
      if (next != null && (earliest == null || next.isBefore(earliest))) {
        earliest = next;
        profileName = profile.name;
      }
    }

    if (earliest == null) return 'No upcoming quiet times';

    final diff = earliest.difference(DateTime.now());
    final formatter = DateFormat('EEE h:mm a');
    if (diff.inHours < 24) {
      if (diff.inMinutes < 60) {
        return '$profileName in ${diff.inMinutes} min';
      }
      return '$profileName in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return '$profileName - ${formatter.format(earliest)}';
  }

  String _getQuickActivateCountdown() {
    if (_quickActivateEnd == null) return '';
    final remaining = _quickActivateEnd!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QuietHour',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDndInstructions,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF7C4DFF),
              child: CustomScrollView(
                slivers: [
                  // Quick activate section
                  SliverToBoxAdapter(
                    child: _buildQuickActivateSection(),
                  ),
                  // Next schedule info
                  if (_profiles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildNextScheduleCard(),
                    ),
                  // Profiles header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Profiles',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_profiles.where((p) => p.isEnabled).length} active',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Profile list
                  _profiles.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final profile = _profiles[index];
                              return ProfileCard(
                                profile: profile,
                                onToggle: (enabled) =>
                                    _toggleProfile(profile, enabled),
                                onTap: () => _openProfileEditor(profile),
                              );
                            },
                            childCount: _profiles.length,
                          ),
                        ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProfileEditor(),
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Profile'),
      ),
    );
  }

  Widget _buildQuickActivateSection() {
    final isActive = _quickActivateEnd != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF7C4DFF), const Color(0xFF651FFF)]
              : [Colors.grey[850]!, Colors.grey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? null
            : Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isActive ? _cancelQuickActivate : _startQuickActivate,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.do_not_disturb_on
                        : Icons.do_not_disturb_off,
                    color: isActive ? Colors.white : const Color(0xFF7C4DFF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Quick Mode Active' : 'Quick Activate',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.grey[200],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? '${_getQuickActivateCountdown()} remaining - Tap to cancel'
                            : 'Tap for 30 minutes of quiet',
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isActive ? Icons.stop_circle_outlined : Icons.play_circle,
                  color: isActive ? Colors.white : const Color(0xFF7C4DFF),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextScheduleCard() {
    final info = _getNextScheduleInfo();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.grey[500], size: 20),
          const SizedBox(width: 10),
          Text(
            'Next: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          Expanded(
            child: Text(
              info,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nightlight_round, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No profiles yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first quiet time profile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showDndInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable Do Not Disturb',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'QuietHour sends notifications to remind you when quiet time '
              'starts and ends. For full Do Not Disturb functionality:',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            _buildInstruction(
              Icons.android,
              'Android',
              'Go to Settings > Sound > Do Not Disturb and allow '
                  'QuietHour to control DND.',
            ),
            const SizedBox(height: 12),
            _buildInstruction(
              Icons.phone_iphone,
              'iOS',
              'Go to Settings > Focus > Do Not Disturb and configure '
                  'an automation schedule, or use QuietHour notifications '
                  'as reminders to toggle Focus mode.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String platform, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7C4DFF), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
