class LlmCacheEntry {
  final String id;
  final String requestHash;
  final String responseJson;
  final DateTime createdAt;

  const LlmCacheEntry({
    required this.id,
    required this.requestHash,
    required this.responseJson,
    required this.createdAt,
  });
}
