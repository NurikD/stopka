/// Whether one more device may be registered from an address that already
/// registered [recentRegistrations] in the last day.
bool registrationAllowed({required int recentRegistrations, required int maxPerDay}) {
  return recentRegistrations < maxPerDay;
}
