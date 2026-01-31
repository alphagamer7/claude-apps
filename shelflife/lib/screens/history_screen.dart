import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shelf_item.dart';
import '../services/database_service.dart';
import '../data/shelf_life_guide.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<ShelfItem> _historyItems = [];
  int _totalTracked = 0;
  int _discardedCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final history = await _db.getHistoryItems();
    final all = await _db.getAllItems();
    final nonActive = all.where((i) => i.status != 'active').toList();
    setState(() {
      _historyItems = history;
      _totalTracked = nonActive.length;
      _discardedCount = nonActive.where((i) => i.status == 'discarded').length;
      _loading = false;
    });
  }

  double get _wastePercentage {
    if (_totalTracked == 0) return 0;
    return (_discardedCount / _totalTracked) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Items Tracked',
                          value: '$_totalTracked',
                          icon: Icons.inventory_2,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey.shade700,
                      ),
                      Expanded(
                        child: _StatBox(
                          label: 'Waste Rate',
                          value: '${_wastePercentage.toStringAsFixed(1)}%',
                          icon: Icons.delete_outline,
                          color: _wastePercentage > 30
                              ? Colors.red
                              : _wastePercentage > 15
                                  ? Colors.orange
                                  : const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                // History list
                Expanded(
                  child: _historyItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history,
                                  size: 64, color: Colors.grey.shade600),
                              const SizedBox(height: 16),
                              Text(
                                'No history yet.\nItems you use or discard\nwill appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _historyItems.length,
                          itemBuilder: (context, index) {
                            final item = _historyItems[index];
                            return _HistoryItemTile(item: item);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class _HistoryItemTile extends StatelessWidget {
  final ShelfItem item;

  const _HistoryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUsed = item.status == 'used';
    final statusColor = isUsed ? const Color(0xFF4CAF50) : Colors.red;
    final statusIcon = isUsed ? Icons.check_circle : Icons.delete;
    final statusText = isUsed ? 'Used up' : 'Discarded';
    final categoryIcon = ShelfLifeGuide.getCategoryIcon(item.category);
    final categoryColor = ShelfLifeGuide.getCategoryColor(item.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(categoryIcon, color: categoryColor, size: 24),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Opened ${DateFormat('MMM d, y').format(item.openedDate)}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
