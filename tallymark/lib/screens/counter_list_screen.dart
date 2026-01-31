import 'package:flutter/material.dart';
import '../models/counter.dart';
import '../services/database_service.dart';
import '../services/csv_export_service.dart';
import 'counter_edit_screen.dart';

class CounterListScreen extends StatefulWidget {
  const CounterListScreen({super.key});

  @override
  State<CounterListScreen> createState() => _CounterListScreenState();
}

class _CounterListScreenState extends State<CounterListScreen> {
  final DatabaseService _db = DatabaseService();
  final CsvExportService _csv = CsvExportService();
  List<Counter> _counters = [];

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    final counters = await _db.getCounters();
    setState(() => _counters = counters);
  }

  Future<void> _deleteCounter(Counter counter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Counter'),
        content: Text('Delete "${counter.name}" and all its history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && counter.id != null) {
      await _db.deleteCounter(counter.id!);
      _loadCounters();
    }
  }

  Future<void> _editCounter(Counter counter) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CounterEditScreen(counter: counter),
      ),
    );
    _loadCounters();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _counters.removeAt(oldIndex);
      _counters.insert(newIndex, item);
    });
    _db.reorderCounters(_counters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counters'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'export') {
                _csv.exportAllHistory();
              } else if (value == 'snapshot') {
                final messenger = ScaffoldMessenger.of(context);
                await _db.performDailySnapshot();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Daily snapshot saved')),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'snapshot',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Save Snapshot'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _counters.isEmpty
          ? Center(
              child: Text(
                'No counters yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withAlpha(100),
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _counters.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final counter = _counters[index];
                final color = Color(counter.color);

                return Dismissible(
                  key: ValueKey(counter.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _deleteCounter(counter);
                    return false; // We handle deletion ourselves
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.withAlpha(60),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  child: ListTile(
                    key: ValueKey('tile_${counter.id}'),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          counter.currentValue.toString(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      counter.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: counter.dailyReset
                        ? Text(
                            'Resets daily',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(80),
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_handle,
                          color: Colors.white.withAlpha(50),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, counter.id),
                    onLongPress: () => _showCounterActions(counter),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CounterEditScreen()),
          );
          _loadCounters();
        },
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCounterActions(Counter counter) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _editCounter(counter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset to 0'),
              onTap: () async {
                Navigator.pop(ctx);
                if (counter.id != null) {
                  await _db.updateCounterValue(counter.id!, 0);
                  _loadCounters();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export History'),
              onTap: () {
                Navigator.pop(ctx);
                _csv.exportCounterHistory(counter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteCounter(counter);
              },
            ),
          ],
        ),
      ),
    );
  }
}
