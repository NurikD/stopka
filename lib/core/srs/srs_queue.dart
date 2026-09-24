/// How many cards a review session will actually serve: everything that is
/// due, plus new cards up to the daily limit. The main screen shows this
/// number, so it must match what the session loads — promising "45" and
/// serving 20 new + the due ones would be a lie.
int reviewQueueSize({required int due, required int fresh, required int newCardLimit}) {
  final servedNew = fresh < newCardLimit ? fresh : newCardLimit;
  return due + servedNew;
}
