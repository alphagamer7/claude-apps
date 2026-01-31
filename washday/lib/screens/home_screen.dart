import 'package:flutter/material.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import '../widgets/laundry_button.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final TimerService timerService;
  final StorageService storageService;

  const HomeScreen({
    super.key,
    required this.timerService,
    required this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.timerService.addListener(_onTimerUpdate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.timerService.removeListener(_onTimerUpdate);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.timerService.onResume();
    }
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onWashTap() {
    switch (widget.timerService.wash.state) {
      case TimerState.idle:
        widget.timerService.startWash();
        break;
      case TimerState.running:
        // Do nothing while running, or optionally allow cancel
        break;
      case TimerState.done:
        widget.timerService.resetWash();
        break;
    }
  }

  void _onDryTap() {
    switch (widget.timerService.dry.state) {
      case TimerState.idle:
        widget.timerService.startDry();
        break;
      case TimerState.running:
        // Do nothing while running
        break;
      case TimerState.done:
        widget.timerService.resetDry();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wash = widget.timerService.wash;
    final dry = widget.timerService.dry;
    final weeklyCount = widget.timerService.weeklyCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WashDay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    storage: widget.storageService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Expanded(
                child: LaundryButton(
                  cycleType: CycleType.wash,
                  timerState: wash.state,
                  remaining: wash.remaining,
                  progress: wash.progress,
                  durationMinutes: widget.storageService.getWashDuration(),
                  onTap: _onWashTap,
                ),
              ),
              Expanded(
                child: LaundryButton(
                  cycleType: CycleType.dry,
                  timerState: dry.state,
                  remaining: dry.remaining,
                  progress: dry.progress,
                  durationMinutes: widget.storageService.getDryDuration(),
                  onTap: _onDryTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'This week: $weeklyCount load${weeklyCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
}
