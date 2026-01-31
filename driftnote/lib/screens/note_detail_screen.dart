import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AudioService _audioService = AudioService();
  final TextEditingController _transcriptionController =
      TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  Note? _note;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasChanges = false;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _loadNote();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _audioService.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() => _duration = dur);
      }
    });
  }

  Future<void> _loadNote() async {
    final note = await _dbService.getNoteById(widget.noteId);
    if (note != null) {
      setState(() {
        _note = note;
        _transcriptionController.text = note.transcription;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_note == null) return;

    if (_isPlaying) {
      await _audioService.pauseAudio();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _audioService.seekTo(Duration.zero);
      }
      await _audioService.playAudio(_note!.audioPath);
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    await _audioService.setPlaybackRate(speed);
  }

  Future<void> _saveChanges() async {
    if (_note == null) return;

    final updatedNote = _note!.copyWith(
      transcription: _transcriptionController.text,
    );

    await _dbService.updateNote(updatedNote);
    setState(() {
      _note = updatedNote;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved'),
          backgroundColor: Color(0xFF009688),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _shareTranscription() async {
    if (_note == null) return;
    await Share.share(_note!.transcription);
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Note',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete this voice note and its recording.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && _note != null) {
      await _audioService.stopAudio();
      // Delete audio file
      try {
        final file = File(_note!.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      await _dbService.deleteNote(_note!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _note == null) return;

    final currentTags = _note!.tagList;
    if (currentTags.contains(tag)) {
      _tagController.clear();
      return;
    }

    currentTags.add(tag);
    final updatedNote = _note!.copyWith(tags: currentTags.join(','));
    _dbService.updateNote(updatedNote);

    setState(() {
      _note = updatedNote;
    });
    _tagController.clear();
  }

  void _removeTag(String tag) {
    if (_note == null) return;

    final currentTags = _note!.tagList;
    currentTags.remove(tag);
    final updatedNote = _note!.copyWith(tags: currentTags.join(','));
    _dbService.updateNote(updatedNote);

    setState(() {
      _note = updatedNote;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioService.stopAudio();
    _transcriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF009688)),
        ),
      );
    }

    if (_note == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Note not found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            if (_hasChanges) {
              await _saveChanges();
            }
            if (mounted) {
              Navigator.pop(context, true);
            }
          },
        ),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF009688)),
              onPressed: _saveChanges,
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareTranscription,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audio Player Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF009688),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Seek bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF009688),
                      inactiveTrackColor: Colors.grey[800],
                      thumbColor: const Color(0xFF009688),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds
                              .toDouble()
                              .clamp(0, _duration.inMilliseconds.toDouble())
                          : 0,
                      max: _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: (value) {
                        _audioService
                            .seekTo(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  // Time labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Playback speed selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _speedOptions.map((speed) {
                      final isSelected = _playbackSpeed == speed;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _setPlaybackSpeed(speed),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF009688)
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${speed}x',
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.grey[400],
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Transcription section
            Text(
              'Transcription',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _transcriptionController,
                maxLines: null,
                minLines: 5,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'No transcription available',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (_) {
                  if (!_hasChanges) {
                    setState(() => _hasChanges = true);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // Tags section
            Text(
              'Tags',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._note!.tagList.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    backgroundColor: Colors.grey[800],
                    deleteIconColor: Colors.grey[400],
                    onDeleted: () => _removeTag(tag),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide.none,
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a tag...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF009688),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Note info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Duration',
                    value: _note!.formattedDuration,
                  ),
                  const Divider(color: Color(0xFF2A2A2A), height: 24),
                  _InfoRow(
                    label: 'Created',
                    value: _formatDateTime(_note!.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $ampm';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
