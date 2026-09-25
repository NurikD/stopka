import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:stopka/core/tts/tts_service.dart';

class _FakeTts extends FlutterTts {
  @override
  Future<dynamic> get getVoices async => [
        {'name': 'ru-ru-x-abc-local', 'locale': 'ru-RU'},
        {'name': 'en-gb-x-rjs-local', 'locale': 'en-GB'},
        {'name': 'en-us-x-iom-network', 'locale': 'en_US'},
        {'name': 'en-us-x-tpf-local', 'locale': 'en_US'},
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('offers only English voices, local US ones first', () async {
    final service = TtsService(tts: _FakeTts(), read: (_) async => null, write: (_, _) async {});
    final voices = await service.englishVoices();
    expect(voices.map((v) => v.name), ['en-us-x-tpf-local', 'en-us-x-iom-network', 'en-gb-x-rjs-local']);
    expect(voices.first.locale, 'en-US');
  });

  test('the chosen voice is remembered, and empty means automatic', () async {
    final store = <String, String>{};
    final service = TtsService(tts: _FakeTts(), read: (k) async => store[k], write: (k, v) async => store[k] = v);
    expect(await service.savedVoice(), isNull);
    await service.saveVoice('en-us-x-tpf-local');
    expect(await service.savedVoice(), 'en-us-x-tpf-local');
    await service.saveVoice(null);
    expect(await service.savedVoice(), isNull);
  });
}
