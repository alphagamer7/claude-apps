class TimerState {
  final DateTime endTime;

  TimerState({required this.endTime});

  bool get isExpired => DateTime.now().isAfter(endTime);

  Duration get remaining {
    final diff = endTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
