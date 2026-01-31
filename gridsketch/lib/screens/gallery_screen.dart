import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../services/database_service.dart';
import '../widgets/grid_thumbnail.dart';
import 'new_artwork_screen.dart';
import 'canvas_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final DatabaseService _db = DatabaseService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    final artworks = await _db.getAllArtworks();
    setState(() {
      _artworks = artworks;
      _loading = false;
    });
  }

  void _openArtwork(Artwork artwork) {
    Navigator.pop(context, artwork);
  }

  Future<void> _createNew() async {
    final result = await Navigator.push<Artwork>(
      context,
      MaterialPageRoute(builder: (context) => const NewArtworkScreen()),
    );
    if (result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CanvasScreen(artwork: result)),
      );
    }
  }

  void _showOptions(Artwork artwork) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Rename', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _renameArtwork(artwork);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white70),
                title: const Text('Export', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _openArtwork(artwork);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteArtwork(artwork);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameArtwork(Artwork artwork) async {
    final controller = TextEditingController(text: artwork.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Rename Artwork', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF9C27B0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && artwork.id != null) {
      final updated = artwork.copyWith(name: newName, updatedAt: DateTime.now());
      await _db.updateArtwork(updated);
      _loadArtworks();
    }
  }

  Future<void> _deleteArtwork(Artwork artwork) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Delete Artwork', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${artwork.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && artwork.id != null) {
      await _db.deleteArtwork(artwork.id!);
      _loadArtworks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _artworks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_on, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        'No artworks yet',
                        style: TextStyle(color: Colors.white38, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap + to create your first pixel art',
                        style: TextStyle(color: Colors.white24, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _artworks.length,
                  itemBuilder: (context, index) {
                    final artwork = _artworks[index];
                    return GestureDetector(
                      onTap: () => _openArtwork(artwork),
                      onLongPress: () => _showOptions(artwork),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final size = constraints.maxWidth < constraints.maxHeight
                                        ? constraints.maxWidth
                                        : constraints.maxHeight;
                                    return Center(
                                      child: GridThumbnail(
                                        artwork: artwork,
                                        size: size,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Column(
                                children: [
                                  Text(
                                    artwork.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${artwork.gridSize}x${artwork.gridSize}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNew,
        backgroundColor: const Color(0xFF9C27B0),
        child: const Icon(Icons.add),
      ),
    );
  }
}
