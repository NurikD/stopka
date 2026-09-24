import 'dart:async';

import 'package:flutter/services.dart';

/// Text shared into the app from other apps. On Android the platform side is
/// `MainActivity`; on other platforms the channel is absent and this reports
/// nothing, which is fine — sharing is an extra way in, never the only one.
class ShareIntake {
  static const channelName = 'stopka/share';

  final MethodChannel _channel;
  final StreamController<String> _controller = StreamController<String>.broadcast();

  ShareIntake([MethodChannel? channel]) : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onText') {
        final text = normalize(call.arguments as String?);
        if (text != null) _controller.add(text);
      }
    });
  }

  /// Text that started the app, if it was launched from a share.
  Future<String?> initialText() async {
    try {
      return normalize(await _channel.invokeMethod<String>('getInitialText'));
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Text shared while the app is already running.
  Stream<String> get texts => _controller.stream;

  void dispose() {
    _channel.setMethodCallHandler(null);
    _controller.close();
  }

  /// Blank shares are dropped; the rest is trimmed.
  static String? normalize(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
