import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/palette.dart';
import '../models/saved_color.dart';
import 'palette_detail_screen.dart';

class PaletteScreen extends StatefulWidget {
  const PaletteScreen({super.key});

  @override
  State<PaletteScreen> createState() => _PaletteScreenState();
}

class _PaletteScreenState extends State<PaletteScreen> {
  final DatabaseService _db = DatabaseService();
  List<Palette> _palettes = [];
  Map<int, List<SavedColor>> _paletteColors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPalettes();
  }

  Future<void> _loadPalettes() async {
    setState(() => _isLoading = true);

    final palettes = await _db.getPalettes();
    final colorsMap = <int, List<SavedColor>>{};

    for (final palette in palettes) {
      if (palette.colorIds.isNotEmpty) {
        colorsMap[palette.id!] =
            await _db.getColorsByIds(palette.colorIds);
      } else {
        colorsMap[palette.id!] = [];
      }
    }

    if (mounted) {
      setState(() {
        _palettes = palettes;
        _paletteColors = colorsMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _createPalette() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('New Palette', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Palette name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE91E63)),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Create',
                style: TextStyle(color: Color(0xFFE91E63))),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      await _db.insertPalette(Palette(name: name.trim()));
      _loadPalettes();
    }
  }

  Future<void> _deletePalette(Palette palette) async {
    if (palette.name == 'Favorites') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the Favorites palette'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Delete Palette', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${palette.name}" and all its colors?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deletePalette(palette.id!);
      _loadPalettes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palettes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPalette,
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFE91E63)))
          : _palettes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.palette_outlined,
                          size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'No palettes yet',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _palettes.length,
                  itemBuilder: (context, index) {
                    final palette = _palettes[index];
                    final colors = _paletteColors[palette.id] ?? [];

                    return Dismissible(
                      key: Key('palette_${palette.id}'),
                      direction: palette.name == 'Favorites'
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        _deletePalette(palette);
                        return false;
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF2A2A2A),
                          ),
                          child: colors.isEmpty
                              ? const Icon(Icons.palette,
                                  color: Color(0xFFE91E63))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    children: colors
                                        .take(4)
                                        .map(
                                          (c) => Expanded(
                                            child: Container(
                                              color: Color.fromARGB(
                                                  255, c.red, c.green, c.blue),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                        ),
                        title: Text(
                          palette.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${colors.length} color${colors.length == 1 ? '' : 's'}',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PaletteDetailScreen(palette: palette),
                            ),
                          );
                          _loadPalettes();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
