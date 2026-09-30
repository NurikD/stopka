import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/update/app_release.dart';

Map<String, Object?> _release(String tag, List<String> apks, {bool draft = false, bool prerelease = false}) => {
      'tag_name': tag,
      'draft': draft,
      'prerelease': prerelease,
      'body': '## Что нового\n- **Иконка** стопки',
      'assets': [
        for (final name in apks) {'name': name, 'browser_download_url': 'https://example.com/$name', 'size': 23000000},
        {'name': 'notes.txt', 'browser_download_url': 'https://example.com/notes.txt', 'size': 10},
      ],
    };

void main() {
  const arm64 = ['arm64-v8a', 'armeabi-v7a', 'armeabi'];

  test('offers a newer release with the APK for this device', () {
    final update = pickUpdate(
      [
        _release('v0.2.0', ['stopka-0.2.0-arm64.apk', 'stopka-0.2.0-armv7.apk']),
      ],
      currentVersion: '0.1.0+1',
      abis: arm64,
    );
    expect(update!.version, '0.2.0');
    expect(update.apkName, 'stopka-0.2.0-arm64.apk');
    expect(update.apkUrl, 'https://example.com/stopka-0.2.0-arm64.apk');
    expect(update.apkSize, 23000000);
  });

  test('a 32-bit phone gets the armv7 APK, and Flutter file names work too', () {
    final update = pickUpdate(
      [
        _release('v0.2.0', ['app-arm64-v8a-release.apk', 'app-armeabi-v7a-release.apk']),
      ],
      currentVersion: '0.1.0',
      abis: const ['armeabi-v7a', 'armeabi'],
    );
    expect(update!.apkName, 'app-armeabi-v7a-release.apk');
  });

  test('the same or an older version is not an update', () {
    expect(pickUpdate([_release('v0.1.0', ['stopka-0.1.0-arm64.apk'])], currentVersion: '0.1.0+1', abis: arm64), isNull);
    expect(pickUpdate([_release('v0.0.9', ['stopka-0.0.9-arm64.apk'])], currentVersion: '0.1.0+1', abis: arm64), isNull);
  });

  test('the newest wins, pre-releases count, drafts and odd tags do not', () {
    final update = pickUpdate(
      [
        _release('v0.4.0', ['stopka-0.4.0-arm64.apk'], draft: true),
        _release('v0.3.0', ['stopka-0.3.0-arm64.apk'], prerelease: true),
        _release('v0.2.0', ['stopka-0.2.0-arm64.apk']),
        _release('nightly', ['stopka-nightly-arm64.apk']),
      ],
      currentVersion: '0.1.0',
      abis: arm64,
    );
    expect(update!.version, '0.3.0');
  });

  test('a release without an APK for this device is skipped; a universal APK fits any', () {
    expect(
      pickUpdate([_release('v0.2.0', ['stopka-0.2.0-x86_64.apk'])], currentVersion: '0.1.0', abis: arm64),
      isNull,
    );
    expect(
      pickUpdate([_release('v0.2.0', ['stopka-0.2.0.apk'])], currentVersion: '0.1.0', abis: arm64)!.apkName,
      'stopka-0.2.0.apk',
    );
  });

  test('release notes lose their Markdown on the phone', () {
    expect(
      plainNotes('## Что нового\n- **Иконка** стопки, `код` и [ссылка](https://x.y)'),
      'Что нового\n- Иконка стопки, код и ссылка',
    );
  });
}
