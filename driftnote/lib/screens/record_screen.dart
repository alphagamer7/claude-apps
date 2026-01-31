import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/database_service.dart';
import '../widgets/waveform_widget.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final AudioService _audioService = AudioService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  bool _isRecording = false;
  bool _isSaving = false;
  String _transcription = '';
  int _durationSeconds = 0;
  Timer? _durationTimer;
  final List<double> _amplitudes = [];
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<String>? _transcriptionSub;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _transcriptionService.initialize();
  }

  Future<void> _startRecording() async {
    final path = await _audioService.startRecording();
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _amplitudes.clear();
    _durationSeconds = 0;
    _transcription = '';

    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _durationSeconds++);
      }
    });

    // Start amplitude monitoring
    _amplitudeSub = _audioService.amplitudeStream.listen((amp) {
      if (mounted) {
        // Normalize amplitude from dB (-160 to 0) to 0.0-1.0
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        setState(() {
          _amplitudes.add(normalized);
        });
      }
    });

    // Start transcription
    await _transcriptionService.startListening();
    _transcriptionSub = _transcriptionService.transcriptionStream.listen((text) {
      if (mounted) {
        setState(() => _transcription = text);
      }
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    setState(() => _isSaving = true);

    _durationTimer?.cancel();
    _amplitudeSub?.cancel();
    _transcriptionSub?.cancel();

    final audioPath = await _audioService.stopRecording();
    final transcription = await _transcriptionService.stopListening();

    // Use the latest transcription we have
    final finalTranscription = transcription.isNotEmpty ? transcription : _transcription;

    if (audioPath != null) {
      final note = Note(
        id: _uuid.v4(),
        audioPath: audioPath,
        transcription: finalTranscription,
        createdAt: DateTime.now(),
        durationSeconds: _durationSeconds,
      );

      await _dbService.insertNote(note);
    }

    setState(() {
      _isRecording = false;
      _isSaving = false;
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String get _formattedDuration {
    final minutes = _durationSeconds ~/ 60;
    final seconds = _durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSub?.cancel();
    _transcriptionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (_isRecording) {
              _stopRecording();
            } else {
              Navigator.pop(context, false);
            }
          },
        ),
        title: const Text(
          'Record',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _isSaving
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF009688)),
                    SizedBox(height: 16),
                    Text(
                      'Saving note...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 32),
                  // Timer
                  Text(
                    _formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Waveform
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: WaveformWidget(
                      amplitudes: _amplitudes,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Live transcription
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.text_fields,
                                size: 16,
                                color: Color(0xFF009688),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Live Transcription',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_isRecording) ...[
                                const SizedBox(width: 8),
                                _PulsingDot(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Text(
                                _transcription.isEmpty
                                    ? (_isRecording
                                        ? 'Listening...'
                                        : 'Tap record to start')
                                    : _transcription,
                                style: TextStyle(
                                  color: _transcription.isEmpty
                                      ? Colors.grey[600]
                                      : Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Record / Stop button
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF009688),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? Colors.red
                                    : const Color(0xFF009688))
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? 'Tap to stop' : 'Tap to record',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.5 + _controller.value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
