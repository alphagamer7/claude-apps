import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class LaundryButton extends StatefulWidget {
  final CycleType cycleType;
  final TimerState timerState;
  final Duration remaining;
  final double progress;
  final int durationMinutes;
  final VoidCallback onTap;

  const LaundryButton({
    super.key,
    required this.cycleType,
    required this.timerState,
    required this.remaining,
    required this.progress,
    required this.durationMinutes,
    required this.onTap,
  });

  @override
  State<LaundryButton> createState() => _LaundryButtonState();
}

class _LaundryButtonState extends State<LaundryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.timerState == TimerState.done) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LaundryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timerState == TimerState.done &&
        oldWidget.timerState != TimerState.done) {
      _pulseController.repeat(reverse: true);
    } else if (widget.timerState != TimerState.done) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _baseColor {
    return widget.cycleType == CycleType.wash
        ? const Color(0xFF03A9F4)
        : const Color(0xFFFF9800);
  }

  Color get _darkColor {
    return widget.cycleType == CycleType.wash
        ? const Color(0xFF0277BD)
        : const Color(0xFFE65100);
  }

  IconData get _icon {
    return widget.cycleType == CycleType.wash
        ? Icons.local_laundry_service
        : Icons.air;
  }

  String get _label {
    return widget.cycleType == CycleType.wash ? 'WASH' : 'DRY';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.timerState == TimerState.done
            ? _pulseAnimation.value
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _baseColor.withValues(
                      alpha:
                          widget.timerState == TimerState.done ? 1.0 : 0.85),
                  _darkColor.withValues(
                      alpha:
                          widget.timerState == TimerState.done ? 1.0 : 0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _baseColor.withValues(alpha: 0.3),
                  blurRadius:
                      widget.timerState == TimerState.running ? 16 : 8,
                  spreadRadius:
                      widget.timerState == TimerState.running ? 2 : 0,
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.timerState) {
      case TimerState.idle:
        return _buildIdleContent();
      case TimerState.running:
        return _buildRunningContent();
      case TimerState.done:
        return _buildDoneContent();
    }
  }

  Widget _buildIdleContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_icon, size: 48, color: Colors.white),
        const SizedBox(height: 12),
        Text(
          _label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to Start',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.durationMinutes} min',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRunningContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 28, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(widget.remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_label in progress...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 48, color: Colors.white),
        const SizedBox(height: 12),
        Text(
          '$_label Done!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to reset',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
