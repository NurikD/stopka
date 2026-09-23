import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/llm/llm_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/text/word_paste_parser.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/ghost_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sticky_action_bar.dart';
import '../../../domain/models/word_card.dart';

enum _Mode { chooser, manual, pasteInput, recognizing, draftReview }

class _DraftEntry {
  String term;
  String translation;
  _DraftEntry(this.term, this.translation);
}

/// The three ways to get words into a set (see PLAN.md): one at a time,
/// pasted as a list, or photographed from the student's own materials.
/// Paste and photo both land on the same editable draft review before
/// anything is saved.
class AddWordsScreen extends ConsumerStatefulWidget {
  final String setId;
  final String level;
  final String grammarTopic;
  final String vocabTopic;

  const AddWordsScreen({
    super.key,
    required this.setId,
    required this.level,
    required this.grammarTopic,
    required this.vocabTopic,
  });

  @override
  ConsumerState<AddWordsScreen> createState() => _AddWordsScreenState();
}

class _AddWordsScreenState extends ConsumerState<AddWordsScreen> {
  _Mode _mode = _Mode.chooser;

  // Manual entry
  final _manualTermController = TextEditingController();
  final _manualTranslationController = TextEditingController();
  final List<String> _addedThisSession = [];
  bool _addingManual = false;

  // Paste entry
  final _pasteController = TextEditingController();

  // Draft review (shared by paste + photo)
  final List<_DraftEntry> _draft = [];
  bool _saving = false;

  @override
  void dispose() {
    _manualTermController.dispose();
    _manualTranslationController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _addManualWord() async {
    final term = _manualTermController.text.trim();
    if (term.isEmpty) return;
    final translation = _manualTranslationController.text.trim();

    setState(() => _addingManual = true);
    final card = await ref.read(wordCardRepositoryProvider).createCard(
          setId: widget.setId,
          term: term,
          translation: translation,
        );
    if (!mounted) return;
    setState(() {
      _addedThisSession.add(term);
      _addingManual = false;
      _manualTermController.clear();
      _manualTranslationController.clear();
    });

    // Enrich in the background; the unit screen's stream picks up the
    // update once it lands, so we don't block on it here.
    ref.read(cardEnrichmentServiceProvider).enrich(
      terms: [term],
      level: widget.level,
      grammarTopic: widget.grammarTopic,
      vocabTopic: widget.vocabTopic,
    ).then((enriched) {
      if (enriched.isEmpty) return null;
      final e = enriched.first;
      return ref.read(wordCardRepositoryProvider).updateCard(card.copyWith(
            translation: card.translation.isEmpty ? e.translation : card.translation,
            transcription: e.transcription,
            partOfSpeech: e.partOfSpeech,
            examples: e.examples,
          ));
    }).catchError((_) {
      // The word is already saved with whatever the user typed; a failed
      // background enrichment (e.g. no Gemini key yet) isn't fatal here.
    });
  }

  void _parsePaste() {
    final parsed = WordPasteParser.parse(_pasteController.text);
    setState(() {
      _draft
        ..clear()
        ..addAll(parsed.map((w) => _DraftEntry(w.term, w.translation)));
      _mode = _Mode.draftReview;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file;
    try {
      file = await picker.pickImage(source: source, imageQuality: 85);
    } catch (_) {
      _showError('Не удалось открыть камеру/галерею.');
      return;
    }
    if (file == null) return;

    setState(() => _mode = _Mode.recognizing);
    try {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? _guessMimeType(file.path);
      final words = await ref.read(wordRecognitionServiceProvider).recognize(
            imageBytes: bytes,
            mimeType: mimeType,
          );
      if (!mounted) return;
      if (words.isEmpty) {
        _showError('Не нашёл слов на фото. Попробуйте другой снимок или введите слова вручную.');
        setState(() => _mode = _Mode.chooser);
        return;
      }
      setState(() {
        _draft
          ..clear()
          ..addAll(words.map((w) => _DraftEntry(w.term, w.translation)));
        _mode = _Mode.draftReview;
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      _showError(e.messageRu);
      setState(() => _mode = _Mode.chooser);
    } finally {
      // We only ever hold the bytes in memory; the picked file itself
      // lives in the OS's own temp/cache area, not something this app
      // persists or uploads anywhere beyond the one recognition request.
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await File(file.path).delete();
        } catch (_) {
          // Best-effort; OS temp cleanup will get it regardless.
        }
      }
    }
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDraft() async {
    final entries = _draft.where((e) => e.term.trim().isNotEmpty).toList();
    if (entries.isEmpty) return;

    setState(() => _saving = true);

    final createdCards = <String, WordCard>{};
    for (final entry in entries) {
      final card = await ref.read(wordCardRepositoryProvider).createCard(
            setId: widget.setId,
            term: entry.term.trim(),
            translation: entry.translation.trim(),
          );
      createdCards[card.term] = card;
    }

    try {
      final enriched = await ref.read(cardEnrichmentServiceProvider).enrich(
            terms: entries.map((e) => e.term.trim()).toList(),
            level: widget.level,
            grammarTopic: widget.grammarTopic,
            vocabTopic: widget.vocabTopic,
          );
      for (final e in enriched) {
        final card = createdCards[e.term];
        if (card == null) continue;
        await ref.read(wordCardRepositoryProvider).updateCard(card.copyWith(
              translation: card.translation.isEmpty ? e.translation : card.translation,
              transcription: e.transcription,
              partOfSpeech: e.partOfSpeech,
              examples: e.examples,
            ));
      }
    } on LlmException catch (e) {
      // Cards are already saved with term/translation; enrichment failing
      // isn't a reason to lose the user's input.
      if (mounted) _showError('${e.messageRu} Слова уже сохранены, обогащение можно повторить позже.');
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(_mode))),
      body: _buildBody(context),
    );
  }

  String _titleFor(_Mode mode) {
    switch (mode) {
      case _Mode.chooser:
        return 'Добавить слова';
      case _Mode.manual:
        return 'Добавить вручную';
      case _Mode.pasteInput:
        return 'Вставить список';
      case _Mode.recognizing:
        return 'Распознаю фото...';
      case _Mode.draftReview:
        return 'Проверьте слова';
    }
  }

  Widget _buildBody(BuildContext context) {
    switch (_mode) {
      case _Mode.chooser:
        return _buildChooser(context);
      case _Mode.manual:
        return _buildManual(context);
      case _Mode.pasteInput:
        return _buildPasteInput(context);
      case _Mode.recognizing:
        return const Center(child: CircularProgressIndicator());
      case _Mode.draftReview:
        return _buildDraftReview(context);
    }
  }

  Widget _buildChooser(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PrimaryButton(label: 'Добавить вручную', onPressed: () => setState(() => _mode = _Mode.manual)),
        const SizedBox(height: AppSpacing.md),
        GhostButton(label: 'Вставить список слов', onPressed: () => setState(() => _mode = _Mode.pasteInput)),
        const SizedBox(height: AppSpacing.md),
        GhostButton(label: 'Сфотографировать список', onPressed: _showPhotoSourceSheet),
      ],
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Камера'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManual(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          controller: _manualTermController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Слово', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _manualTranslationController,
          decoration: const InputDecoration(
            labelText: 'Перевод (необязательно — ИИ подберёт сам)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addManualWord(),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(label: 'Добавить', onPressed: _addManualWord, loading: _addingManual),
        if (_addedThisSession.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Добавлено: ${_addedThisSession.join(', ')}',
            style: AppTypography.caption.copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildPasteInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'По одному слову на строку или через запятую. Формат "word - перевод" тоже понимаю.',
            style: AppTypography.caption.copyWith(color: context.colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _pasteController,
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Разобрать', onPressed: _parsePaste),
        ],
      ),
    );
  }

  Widget _buildDraftReview(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _draft.length,
            itemBuilder: (context, i) {
              final entry = _draft[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.term,
                        decoration: const InputDecoration(labelText: 'Слово', isDense: true),
                        onChanged: (v) => entry.term = v,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.translation,
                        decoration: const InputDecoration(labelText: 'Перевод', isDense: true),
                        onChanged: (v) => entry.translation = v,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textMuted),
                      onPressed: () => setState(() => _draft.removeAt(i)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        StickyActionBar(
          children: [
            PrimaryButton(
              label: 'Сохранить ${_draft.length} слов',
              onPressed: _draft.isEmpty ? null : _saveDraft,
              loading: _saving,
            ),
          ],
        ),
      ],
    );
  }
}
