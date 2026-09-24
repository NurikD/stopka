import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/share/share_intake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ShareIntake.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('reads the text that started the app', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'getInitialText' ? '  cat - кот\ndog - собака \n' : null,
    );
    final intake = ShareIntake(channel);
    expect(await intake.initialText(), 'cat - кот\ndog - собака');
    intake.dispose();
  });

  test('without the platform side there is simply nothing to read', () async {
    final intake = ShareIntake(channel);
    expect(await intake.initialText(), isNull);
    intake.dispose();
  });

  test('a blank share is ignored', () {
    expect(ShareIntake.normalize('   \n'), isNull);
    expect(ShareIntake.normalize(null), isNull);
    expect(ShareIntake.normalize(' word '), 'word');
  });

  test('text shared while running arrives on the stream', () async {
    final intake = ShareIntake(channel);
    final first = intake.texts.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      ShareIntake.channelName,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('onText', ' apple, pear ')),
      (_) {},
    );
    expect(await first, 'apple, pear');
    intake.dispose();
  });
}
