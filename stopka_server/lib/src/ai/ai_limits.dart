/// The UTC day a request counts against, as `yyyy-MM-dd`.
String dayKey(DateTime now) {
  final utc = now.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)}';
}

/// When the daily counters start again: the next UTC midnight.
DateTime nextResetUtc(DateTime now) {
  final utc = now.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day).add(const Duration(days: 1));
}

enum LimitVerdict {
  allowed,

  /// The whole proxy is switched off in the config.
  disabled,

  /// All devices together reached the daily ceiling.
  budgetExhausted,

  /// This device used up its allowance for this kind.
  deviceLimit,
}

/// Decides whether one more request may go to the provider. The order matters:
/// the master switch and the global budget come before any per-device limit,
/// so a leaked token can never spend more than the ceiling.
LimitVerdict decideRequest({
  required bool enabled,
  required int usedByDeviceForKind,
  required int deviceLimitForKind,
  required int usedByAllToday,
  required int globalDailyRequests,
}) {
  if (!enabled) return LimitVerdict.disabled;
  if (usedByAllToday >= globalDailyRequests) return LimitVerdict.budgetExhausted;
  if (usedByDeviceForKind >= deviceLimitForKind) return LimitVerdict.deviceLimit;
  return LimitVerdict.allowed;
}
