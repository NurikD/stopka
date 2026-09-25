import 'package:stopka_server/src/logic/app_version.dart';
import 'package:test/test.dart';

void main() {
  test('versions compare by major, minor, patch, then build', () {
    expect(AppVersion.tryParse('1.2.3')!.compareTo(AppVersion.tryParse('1.2.4')!), lessThan(0));
    expect(AppVersion.tryParse('1.10.0')!.compareTo(AppVersion.tryParse('1.9.9')!), greaterThan(0));
    expect(AppVersion.tryParse('2.0.0')!.compareTo(AppVersion.tryParse('1.99.99')!), greaterThan(0));
    expect(AppVersion.tryParse('1.0.0+2')!.compareTo(AppVersion.tryParse('1.0.0+10')!), lessThan(0));
    expect(AppVersion.tryParse('1.0.0')!.compareTo(AppVersion.tryParse('1.0.0+0')!), 0);
  });

  test('anything that is not N.N.N[+N] does not parse', () {
    expect(AppVersion.tryParse('1.2'), isNull);
    expect(AppVersion.tryParse('v1.2.3'), isNull);
    expect(AppVersion.tryParse(''), isNull);
    expect(AppVersion.tryParse('1.2.3-beta'), isNull);
  });

  test('an app at or above the minimum is supported, below it is not', () {
    expect(isAppVersionSupported('1.0.0+1', '1.0.0'), isTrue);
    expect(isAppVersionSupported('1.4.0', '1.3.9'), isTrue);
    expect(isAppVersionSupported('1.0.0', '1.0.1'), isFalse);
  });

  test('an app that cannot state its version is too old; no usable minimum means everything passes', () {
    expect(isAppVersionSupported('garbage', '1.0.0'), isFalse);
    expect(isAppVersionSupported('garbage', 'not-a-version'), isTrue);
  });
}
