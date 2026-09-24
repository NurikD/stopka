import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsVoice {
  final String name;
  final String locale;

  const TtsVoice(this.name, this.locale);
}

/// Speaks English words with the on-device engine. Quality depends on the
/// voice installed on the phone, so the voice is chosen (and can be changed
/// in the profile) instead of relying on whatever the system defaults to.
class TtsService {
  static const _voiceKey = 'tts_voice';
  static const _storage = FlutterSecureStorage();

  final FlutterTts _tts;
  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;
  bool _configured = false;

  TtsService({
    FlutterTts? tts,
    Future<String?> Function(String key)? read,
    Future<void> Function(String key, String value)? write,
  })  : _tts = tts ?? FlutterTts(),
        _read = read ?? ((key) => _storage.read(key: key)),
        _write = write ?? ((key, value) => _storage.write(key: key, value: value));

  /// English voices installed on the device, best guess first: local
  /// (works offline) US voices before others.
  Future<List<TtsVoice>> englishVoices() async {
    final raw = await _tts.getVoices;
    if (raw is! List) return const [];
    final voices = <TtsVoice>[];
    for (final v in raw) {
      if (v is! Map) continue;
      final name = v['name']?.toString() ?? '';
      final locale = (v['locale']?.toString() ?? '').replaceAll('_', '-');
      if (name.isNotEmpty && locale.toLowerCase().startsWith('en')) voices.add(TtsVoice(name, locale));
    }
    voices.sort((a, b) {
      int rank(TtsVoice v) => (v.locale.toLowerCase() == 'en-us' ? 0 : 2) + (v.name.contains('network') ? 1 : 0);
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.name.compareTo(b.name);
    });
    return voices;
  }

  /// The chosen voice name, or null for "automatic".
  Future<String?> savedVoice() async {
    final name = await _read(_voiceKey);
    return (name == null || name.isEmpty) ? null : name;
  }

  Future<void> saveVoice(String? name) async {
    await _write(_voiceKey, name ?? '');
    _configured = false;
  }

  /// False when the device has no English speech data at all — the system
  /// would then read the word with a foreign voice, which is what sounds like
  /// a heavy accent.
  Future<bool> hasEnglish() async {
    final result = await _tts.isLanguageAvailable('en-US');
    return result == true || result == 1;
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setLanguage('en-US');
    final voice = await savedVoice();
    if (voice != null) {
      final voices = await englishVoices();
      final match = voices.where((v) => v.name == voice).firstOrNull;
      if (match != null) await _tts.setVoice({'name': match.name, 'locale': match.locale});
    }
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    _configured = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(text);
  }
}
