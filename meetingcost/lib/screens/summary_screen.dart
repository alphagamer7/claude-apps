import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meeting.dart';
import '../services/cost_calculator.dart';
import '../services/database_service.dart';
import '../widgets/cost_display.dart';
import '../widgets/meeting_stat.dart';

class SummaryScreen extends StatefulWidget {
  final int attendeeCount;
  final double hourlyRate;
  final int durationSeconds;
  final double totalCost;

  const SummaryScreen({
    super.key,
    required this.attendeeCount,
    required this.hourlyRate,
    required this.durationSeconds,
    required this.totalCost,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _saved = false;

  String get _formattedDuration {
    final h = widget.durationSeconds ~/ 3600;
    final m = (widget.durationSeconds % 3600) ~/ 60;
    final s = widget.durationSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  double get _costPerPerson =>
      widget.attendeeCount > 0 ? widget.totalCost / widget.attendeeCount : 0;

  double get _costPerMinute => widget.durationSeconds > 0
      ? widget.totalCost / (widget.durationSeconds / 60)
      : 0;

  Future<void> _saveMeeting() async {
    final meeting = Meeting(
      attendeeCount: widget.attendeeCount,
      hourlyRate: widget.hourlyRate,
      durationSeconds: widget.durationSeconds,
      totalCost: widget.totalCost,
    );
    await DatabaseService.instance.insertMeeting(meeting);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting saved to history'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  void _shareSummary() {
    final text = StringBuffer()
      ..writeln('Meeting Cost Summary')
      ..writeln('====================')
      ..writeln('Total Cost: \$${widget.totalCost.toStringAsFixed(2)}')
      ..writeln('Duration: $_formattedDuration')
      ..writeln('Attendees: ${widget.attendeeCount}')
      ..writeln(
          'Cost per Person: \$${_costPerPerson.toStringAsFixed(2)}')
      ..writeln(
          'Cost per Minute: \$${_costPerMinute.toStringAsFixed(2)}')
      ..writeln()
      ..writeln("That's equivalent to:");

    for (final equiv in CostCalculator.funEquivalents(widget.totalCost)) {
      text.writeln(
          '  - ${equiv.count.toStringAsFixed(1)} ${equiv.name}');
    }

    text.writeln();
    text.writeln('Tracked with MeetingCost');

    Share.share(text.toString());
  }

  IconData _iconForEquivalent(String icon) {
    switch (icon) {
      case 'coffee':
        return Icons.coffee;
      case 'lunch':
        return Icons.restaurant;
      case 'netflix':
        return Icons.tv;
      case 'music':
        return Icons.music_note;
      case 'car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'book':
        return Icons.menu_book;
      case 'pizza':
        return Icons.local_pizza;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final equivalents = CostCalculator.funEquivalents(widget.totalCost);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meeting Summary'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'This meeting cost',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              CostDisplay(
                cost: widget.totalCost,
                fontSize: 56,
                color: const Color(0xFFFF5722),
              ),
              const SizedBox(height: 32),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: MeetingStat(
                      label: 'Duration',
                      value: _formattedDuration,
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MeetingStat(
                      label: 'Attendees',
                      value: '${widget.attendeeCount}',
                      icon: Icons.people,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MeetingStat(
                      label: 'Cost / Person',
                      value: '\$${_costPerPerson.toStringAsFixed(2)}',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MeetingStat(
                      label: 'Cost / Minute',
                      value: '\$${_costPerMinute.toStringAsFixed(2)}',
                      icon: Icons.speed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Fun equivalents
              if (equivalents.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "That's equivalent to...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...equivalents.map((equiv) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForEquivalent(equiv.icon),
                                  color: const Color(0xFFFF5722),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${equiv.count.toStringAsFixed(1)} ${equiv.name}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _saved ? null : _saveMeeting,
                        icon: Icon(_saved ? Icons.check : Icons.save),
                        label: Text(_saved ? 'Saved' : 'Save Meeting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _saved
                              ? Colors.green.withValues(alpha: 0.3)
                              : const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _shareSummary,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Start New Meeting'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
