import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/split_session.dart';
import '../services/database_service.dart';

class SummaryScreen extends StatefulWidget {
  final SplitSession session;

  const SummaryScreen({super.key, required this.session});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _saved = false;

  Future<void> _saveSession() async {
    if (_saved) return;
    final db = DatabaseService();
    await db.insertSession(widget.session);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Split saved to history'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  String _buildShareText() {
    final session = widget.session;
    final totals = session.getPerPersonTotals();
    final buffer = StringBuffer();

    buffer.writeln('SplitSnap Receipt Split');
    buffer.writeln('========================');
    buffer.writeln();

    for (final person in session.people) {
      final items = session.getItemsForPerson(person);
      final personTotal = totals[person] ?? 0.0;

      buffer.writeln('$person: \$${personTotal.toStringAsFixed(2)}');
      for (final item in items) {
        buffer.writeln('  - ${item.name}: \$${item.price.toStringAsFixed(2)}');
      }
      buffer.writeln();
    }

    buffer.writeln('------------------------');
    buffer.writeln('Subtotal: \$${session.subtotal.toStringAsFixed(2)}');
    buffer.writeln('Tax: \$${session.taxAmount.toStringAsFixed(2)}');
    buffer.writeln('Tip: \$${session.tipAmount.toStringAsFixed(2)}');
    buffer.writeln('Total: \$${session.total.toStringAsFixed(2)}');

    return buffer.toString();
  }

  void _share() {
    Share.share(_buildShareText());
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final totals = session.getPerPersonTotals();

    // Count unassigned items
    final unassignedItems =
        session.items.where((i) => i.assignedPerson == null).toList();
    final unassignedTotal =
        unassignedItems.fold(0.0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(
            onPressed: _saveSession,
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFF4CAF50),
            ),
            tooltip: 'Save to history',
          ),
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.share, color: Color(0xFF4CAF50)),
            tooltip: 'Share',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Per-person breakdown
          ...session.people.map((person) {
            final items = session.getItemsForPerson(person);
            final personTotal = totals[person] ?? 0.0;
            final itemsSubtotal =
                items.fold(0.0, (double sum, item) => sum + item.price);

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              child: Text(
                                person[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              person,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${personTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        color: Colors.white70)),
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )),
                      if (session.taxAmount > 0 || session.tipAmount > 0) ...[
                        const Divider(color: Colors.grey),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items subtotal',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(
                                '\$${itemsSubtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('+ Tax & Tip share',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(
                                '\$${(personTotal - itemsSubtotal).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('No items assigned',
                            style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            );
          }),

          // Unassigned items warning
          if (unassignedItems.isNotEmpty)
            Card(
              color: Colors.orange[900]?.withValues(alpha: 0.3),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Unassigned Items',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...unassignedItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.name,
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              Text('\$${item.price.toStringAsFixed(2)}',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )),
                    const Divider(color: Colors.orange),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unassigned total',
                            style: TextStyle(color: Colors.orange)),
                        Text('\$${unassignedTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Totals card
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow('Subtotal', session.subtotal),
                  const SizedBox(height: 8),
                  _totalRow('Tax', session.taxAmount),
                  const SizedBox(height: 8),
                  _totalRow('Tip', session.tipAmount),
                  const Divider(color: Colors.grey, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${session.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share),
              label: const Text('Share Split', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                _saveSession();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.check),
              label: const Text('Save & Done', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                side: const BorderSide(color: Color(0xFF4CAF50)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}
