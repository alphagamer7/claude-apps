import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Meeting> _meetings = [];
  Map<String, double> _stats = {};
  bool _isLoading = true;
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    final db = DatabaseService.instance;

    List<Meeting> meetings;
    if (_dateFilter != null) {
      meetings = await db.getMeetingsByDateRange(
        _dateFilter!.start,
        _dateFilter!.end.add(const Duration(days: 1)),
      );
    } else {
      meetings = await db.getAllMeetings();
    }

    final stats = await db.getStats();

    setState(() {
      _meetings = meetings;
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateFilter ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF5722),
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      _dateFilter = range;
      _loadMeetings();
    }
  }

  void _clearFilter() {
    _dateFilter = null;
    _loadMeetings();
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Delete Meeting?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && meeting.id != null) {
      await DatabaseService.instance.deleteMeeting(meeting.id!);
      _loadMeetings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _dateFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _dateFilter != null ? const Color(0xFFFF5722) : null,
            ),
            onPressed: _pickDateRange,
            tooltip: 'Filter by date',
          ),
          if (_dateFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilter,
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meetings.isEmpty
              ? _buildEmptyState()
              : _buildContent(dateFormat, timeFormat),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _dateFilter != null
                ? 'No meetings in this date range'
                : 'No meetings recorded yet',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a meeting to see it here',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DateFormat dateFormat, DateFormat timeFormat) {
    return Column(
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF5722).withValues(alpha: 0.2),
                const Color(0xFFFF5722).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF5722).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Spent',
                  '\$${_stats['totalCost']?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  'Average Cost',
                  '\$${_stats['avgCost']?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  'Meetings',
                  '${_stats['count']?.toInt() ?? 0}',
                ),
              ),
            ],
          ),
        ),

        if (_dateFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing: ${dateFormat.format(_dateFilter!.start)} - ${dateFormat.format(_dateFilter!.end)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),

        // Meeting list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _meetings.length,
            itemBuilder: (context, index) {
              final meeting = _meetings[index];
              return _buildMeetingCard(meeting, dateFormat, timeFormat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(
      Meeting meeting, DateFormat dateFormat, DateFormat timeFormat) {
    return Dismissible(
      key: Key('meeting-${meeting.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        _deleteMeeting(meeting);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cost
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${meeting.totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                      color: Color(0xFFFF5722),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(meeting.createdAt)} at '
                    '${timeFormat.format(meeting.createdAt)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.people, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '${meeting.attendeeCount}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        meeting.formattedDuration,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${meeting.hourlyRate.toStringAsFixed(0)}/hr per person',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
