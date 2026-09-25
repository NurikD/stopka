// ignore_for_file: prefer_initializing_formals -- named params stay public while fields are private.
import 'package:flutter/foundation.dart';

import '../../domain/models/unit_pack.dart';
import '../../domain/repositories/pack_repository.dart';
import '../llm/llm_exception.dart';
import 'content_source.dart';
import 'pack_content.dart';

/// Prepares and caches the parts of a unit pack. Parts are generated one by
/// one so what is ready can be opened without waiting for the rest, and a
/// bad part is regenerated on its own.
class PackService {
  final PackRepository _repo;
  final ContentSource _source;
  final Future<bool> Function() _hasKey;

  /// `"<packId>/<part>"` of parts being generated right now.
  final ValueNotifier<Set<String>> generating = ValueNotifier(const {});

  /// Last error message per `"<packId>/<part>"`, for the UI.
  final Map<String, String> lastError = {};

  PackService({
    required PackRepository repo,
    required ContentSource source,
    required Future<bool> Function() hasKey,
  })  : _repo = repo,
        _source = source,
        _hasKey = hasKey;

  static String slot(String packId, PackPart part) => '$packId/${part.name}';

  Future<UnitPack> open(PackKey key) => _repo.getOrCreate(key);

  bool isGenerating(String packId, PackPart part) => generating.value.contains(slot(packId, part));

  void _setGenerating(String slotId, bool on) {
    final next = {...generating.value};
    on ? next.add(slotId) : next.remove(slotId);
    generating.value = next;
  }

  /// Generates every part that is not ready yet, one after another. Does
  /// nothing without a key: the pack just stays as it is.
  Future<void> generateMissing(String packId, PackKey key) async {
    if (!await _hasKey()) return;
    for (final part in PackPart.values) {
      final pack = await _repo.getPack(packId);
      if (pack == null) return;
      final status = pack.statusOf(part);
      if (status == PartStatus.ready || isGenerating(packId, part)) continue;
      await generatePart(packId, key, part);
    }
  }

  /// Generates one part now. Returns true when it is ready afterwards.
  Future<bool> generatePart(String packId, PackKey key, PackPart part) async {
    final slotId = slot(packId, part);
    if (generating.value.contains(slotId)) return false;
    if (!await _hasKey()) {
      lastError[slotId] = 'Для подготовки материала нужен ключ Gemini. Добавьте его в «Профиле».';
      return false;
    }
    _setGenerating(slotId, true);
    lastError.remove(slotId);
    try {
      final payload = await _source.fetchPart(key, part);
      await _repo.setPart(packId, part, payload: payload, status: PartStatus.ready);
      return true;
    } on LlmException catch (e) {
      lastError[slotId] = e.messageRu;
      await _repo.setPart(packId, part, status: PartStatus.failed);
      return false;
    } finally {
      _setGenerating(slotId, false);
    }
  }

  /// "Материал плохой": the part is flagged, dropped from the cache and
  /// generated again.
  Future<bool> flagAndRegenerate(String packId, PackKey key, PackPart part) async {
    await _repo.setPart(packId, part, status: PartStatus.flagged);
    return generatePart(packId, key, part);
  }
}
