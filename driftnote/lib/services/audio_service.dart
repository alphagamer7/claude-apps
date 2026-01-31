import 'dart:async';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Uuid _uuid = const Uuid();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  Stream<Amplitude> get amplitudeStream {
    return Stream.periodic(const Duration(milliseconds: 100)).asyncMap((_) async {
      if (_isRecording) {
        return await _recorder.getAmplitude();
      }
      return Amplitude(current: -160.0, max: -160.0);
    });
  }

  Future<String?> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'driftnote_${_uuid.v4()}.m4a';
        final path = '${dir.path}/$fileName';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        _isRecording = true;
        _currentRecordingPath = path;
        return path;
      }
      return null;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path ?? _currentRecordingPath;
    } catch (e) {
      _isRecording = false;
      return _currentRecordingPath;
    }
  }

  Future<void> playAudio(String path) async {
    try {
      await _player.play(DeviceFileSource(path));
      _isPlaying = true;
    } catch (e) {
      _isPlaying = false;
    }
  }

  Future<void> pauseAudio() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resumeAudio() async {
    await _player.resume();
    _isPlaying = true;
  }

  Future<void> stopAudio() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setPlaybackRate(double rate) async {
    await _player.setPlaybackRate(rate);
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
