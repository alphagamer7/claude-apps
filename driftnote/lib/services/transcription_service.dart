import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class TranscriptionService {
  static final TranscriptionService _instance = TranscriptionService._internal();
  factory TranscriptionService() => _instance;
  TranscriptionService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  String _currentTranscription = '';
  String _finalTranscription = '';

  String get currentTranscription => _finalTranscription + _currentTranscription;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    return _isInitialized;
  }

  void _onError(SpeechRecognitionError error) {
    if (error.errorMsg == 'error_no_match' || error.errorMsg == 'error_speech_timeout') {
      // These are normal - just means silence detected, restart if still listening
      if (_isListening) {
        _restartListening();
      }
    }
  }

  void _onStatus(String status) {
    if (status == 'notListening' && _isListening) {
      _restartListening();
    }
  }

  Future<void> _restartListening() async {
    if (!_isListening) return;
    // Add a small delay before restarting
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_isListening) return;

    try {
      await _speechToText.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      // Ignore restart errors
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _currentTranscription = '';
    _finalTranscription = '';
    _isListening = true;

    await _speechToText.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    _currentTranscription = result.recognizedWords;

    if (result.finalResult) {
      if (_currentTranscription.isNotEmpty) {
        if (_finalTranscription.isNotEmpty) {
          _finalTranscription += ' ';
        }
        _finalTranscription += _currentTranscription;
      }
      _currentTranscription = '';
    }

    _transcriptionController.add(currentTranscription);
  }

  Future<String> stopListening() async {
    _isListening = false;
    await _speechToText.stop();

    final result = currentTranscription;
    _currentTranscription = '';
    _finalTranscription = '';
    return result;
  }

  void dispose() {
    _transcriptionController.close();
  }
}
