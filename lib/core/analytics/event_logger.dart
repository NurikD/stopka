/// All significant user actions flow through one logger so a real analytics
/// provider can be wired in later without touching call sites.
abstract class EventLogger {
  void log(String eventName, [Map<String, Object?> params]);
}

class NoopEventLogger implements EventLogger {
  @override
  void log(String eventName, [Map<String, Object?> params = const {}]) {}
}
