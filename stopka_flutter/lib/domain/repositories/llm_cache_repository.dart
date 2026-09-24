abstract class LlmCacheRepository {
  /// Cached response JSON for [requestHash], or null on a cache miss.
  Future<String?> get(String requestHash);

  Future<void> put(String requestHash, String responseJson);
}
