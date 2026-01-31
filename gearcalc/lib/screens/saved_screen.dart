import 'package:flutter/material.dart';
import '../models/drivetrain.dart';
import '../services/storage_service.dart';
import '../widgets/setup_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Drivetrain> _saved = [];
  bool _loading = true;
  final Set<String> _selectedIds = {};
  bool _compareMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await StorageService.loadAll();
    setState(() {
      _saved = items;
      _loading = false;
    });
  }

  Future<void> _delete(Drivetrain dt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title:
            const Text('Delete Setup', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${dt.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.delete(dt.id);
      _selectedIds.remove(dt.id);
      await _load();
    }
  }

  void _onTap(Drivetrain dt) {
    if (_compareMode) {
      setState(() {
        if (_selectedIds.contains(dt.id)) {
          _selectedIds.remove(dt.id);
        } else if (_selectedIds.length < 2) {
          _selectedIds.add(dt.id);
        }
      });
    } else {
      // Load this setup
      Navigator.pop(context, {'load': dt});
    }
  }

  void _compare() {
    if (_selectedIds.length == 2) {
      final selected =
          _saved.where((d) => _selectedIds.contains(d.id)).toList();
      Navigator.pop(context, {
        'load': selected[0],
        'compare': selected[1],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_compareMode ? 'Select Two to Compare' : 'Saved Setups'),
        actions: [
          if (!_compareMode && _saved.length >= 2)
            TextButton.icon(
              onPressed: () => setState(() => _compareMode = true),
              icon: const Icon(Icons.compare_arrows,
                  color: Color(0xFFCDDC39), size: 18),
              label: const Text('Compare',
                  style: TextStyle(color: Color(0xFFCDDC39), fontSize: 12)),
            ),
          if (_compareMode)
            TextButton(
              onPressed: () => setState(() {
                _compareMode = false;
                _selectedIds.clear();
              }),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _saved.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _compareMode && _selectedIds.length == 2
          ? FloatingActionButton.extended(
              onPressed: _compare,
              backgroundColor: const Color(0xFFCDDC39),
              icon: const Icon(Icons.compare_arrows, color: Colors.black),
              label: const Text('Compare',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text('No saved setups',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          SizedBox(height: 8),
          Text('Save a drivetrain setup from the home screen',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _saved.length,
      itemBuilder: (context, index) {
        final dt = _saved[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SetupCard(
            drivetrain: dt,
            isSelected: _selectedIds.contains(dt.id),
            onTap: () => _onTap(dt),
            onLongPress: () => _delete(dt),
          ),
        );
      },
    );
  }
}
