import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper so features call one `speak(word)` method instead of each
/// configuring FlutterTts (language, rate) themselves.
class TtsService {
  final FlutterTts _tts;
  bool _configured = false;

  TtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _configured = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(text);
  }
}
