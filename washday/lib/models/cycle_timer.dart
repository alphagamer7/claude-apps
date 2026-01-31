enum CycleType { wash, dry }

enum TimerState { idle, running, done }

class CycleTimer {
  final CycleType type;
  TimerState state = TimerState.idle;
  int? _startTimeMs;
  int? _durationMs;

  CycleTimer({required this.type});

  int? get startTimeMs => _startTimeMs;
  int? get durationMs => _durationMs;

  Duration get remaining {
    if (_startTimeMs == null || _durationMs == null) return Duration.zero;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startTimeMs!;
    final rem = _durationMs! - elapsed;
    return rem > 0 ? Duration(milliseconds: rem) : Duration.zero;
  }

  double get progress {
    if (_durationMs == null || _durationMs == 0) return 0.0;
    if (_startTimeMs == null) return 0.0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startTimeMs!;
    final p = elapsed / _durationMs!;
    return p.clamp(0.0, 1.0);
  }

  void start(int durationMinutes) {
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _durationMs = durationMinutes * 60 * 1000;
    state = TimerState.running;
  }

  void restore(int startTimeMs, int durationMs) {
    _startTimeMs = startTimeMs;
    _durationMs = durationMs;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTimeMs;
    if (elapsed >= durationMs) {
      state = TimerState.done;
    } else {
      state = TimerState.running;
    }
  }

  void reset() {
    _startTimeMs = null;
    _durationMs = null;
    state = TimerState.idle;
  }

  void checkCompletion() {
    if (state == TimerState.running && remaining == Duration.zero) {
      state = TimerState.done;
    }
  }
}
