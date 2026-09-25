import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/llm/llm_exception.dart';
import '../../core/llm/unit_page_service.dart';
import '../../core/onboarding/onboarding_service.dart';
import '../../core/onboarding/starter_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/sticky_action_bar.dart';

const int _lastStep = 2;

/// Three quick questions — level, interests, what the learner is studying now —
/// then a first word set is created and [onDone] takes them to the dictation.
/// Nothing here needs a Gemini key: it only makes the result more personal.
class OnboardingScreen extends ConsumerStatefulWidget {
  final void Function(OnboardingResult result) onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String _level = '';
  final List<String> _interests = [];
  final _topicController = TextEditingController();
  UnitPageInfo? _page;
  bool _reading = false;
  bool _finishing = false;
  String? _message;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _toggleInterest(String id) {
    setState(() {
      if (_interests.contains(id)) {
        _interests.remove(id);
      } else if (_interests.length < maxInterests) {
        _interests.add(id);
      }
    });
  }

  Future<void> _photo() async {
    final hasKey = await ref.read(aiAvailabilityProvider).isAvailable();
    if (!mounted) return;
    if (!hasKey) {
      setState(() => _message = 'Фото страницы сейчас не распознать: нет связи с сервером. Впишите тему вручную. '
          'или просто впишите тему выше.');
      return;
    }

    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    } catch (_) {
      if (mounted) setState(() => _message = 'Не удалось открыть камеру.');
      return;
    }
    if (file == null) return;

    setState(() {
      _reading = true;
      _message = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final info = await ref.read(unitPageServiceProvider).read(
            imageBytes: bytes,
            mimeType: file.mimeType ?? (file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg'),
          );
      if (!mounted) return;
      setState(() {
        _page = info;
        _reading = false;
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _reading = false;
        _message = e.messageRu;
      });
    }
  }

  Future<void> _finish() async {
    setState(() {
      _finishing = true;
      _message = null;
    });
    try {
      final result = await ref.read(onboardingServiceProvider).finish(
            level: _level,
            interestIds: List.of(_interests),
            topic: _topicController.text,
            page: _page,
          );
      if (!mounted) return;
      widget.onDone(result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _message = 'Не удалось подготовить первое занятие. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppHeaderBar(meta: '${_step + 1} / ${_lastStep + 1}'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s22),
        children: [
          Text(_title, style: AppTypography.title.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.s8),
          Text(_hint, style: AppTypography.caption.copyWith(color: colors.muted)),
          const SizedBox(height: AppSpacing.s22),
          switch (_step) {
            0 => _levelStep(),
            1 => _interestsStep(),
            _ => _topicStep(colors),
          },
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.s14),
            Text(_message!, style: AppTypography.bodyText.copyWith(color: colors.danger)),
          ],
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        flexes: _step == 0 ? null : const [1, 2],
        children: [
          if (_step > 0) GhostButton(label: 'Назад', onPressed: _finishing ? null : () => setState(() => _step--)),
          if (_step < _lastStep)
            PrimaryButton(
              label: 'Дальше',
              trailingIcon: Icons.arrow_forward,
              onPressed: () => setState(() => _step++),
            )
          else
            PrimaryButton(
              label: _topicController.text.trim().isEmpty && _page == null ? 'Пропустить и начать' : 'Начать',
              trailingIcon: Icons.arrow_forward,
              onPressed: _reading ? null : _finish,
              loading: _finishing,
            ),
        ],
      ),
    );
  }

  String get _title => switch (_step) {
        0 => 'Ваш уровень',
        1 => 'Что вам интересно',
        _ => 'Что проходите сейчас',
      };

  String get _hint => switch (_step) {
        0 => 'Если не уверены — выберите «Не знаю», начнём с A2 и подстроимся.',
        1 => 'Выберите до $maxInterests тем, слова будем подбирать под них.',
        _ => 'Тема урока или фото страницы. Можно пропустить — возьмём тему по уровню.',
      };

  Widget _levelStep() {
    return _TileWrap(
      children: [
        for (final choice in levelChoices)
          ChoiceTile(
            label: choice.label,
            selected: _level == choice.id,
            onTap: () => setState(() => _level = choice.id),
          ),
      ],
    );
  }

  Widget _interestsStep() {
    return _TileWrap(
      children: [
        for (final interest in interests)
          ChoiceTile(
            label: interest.label,
            selected: _interests.contains(interest.id),
            onTap: () => _toggleInterest(interest.id),
          ),
      ],
    );
  }

  Widget _topicStep(AppColorTokens colors) {
    final page = _page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Тема',
          child: TextField(
            controller: _topicController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Например, Past simple или путешествия'),
          ),
        ),
        const SizedBox(height: AppSpacing.s14),
        GhostButton(
          label: _reading ? 'Читаю страницу…' : 'Сфотографировать страницу',
          onPressed: _reading ? null : _photo,
        ),
        if (page != null) ...[
          const SizedBox(height: AppSpacing.s14),
          Text(
            [page.code, page.title, page.grammarTopic, page.vocabTopic].where((t) => t.isNotEmpty).join(' · '),
            style: AppTypography.monoMeta.copyWith(color: colors.accent),
          ),
        ],
      ],
    );
  }
}

class _TileWrap extends StatelessWidget {
  final List<Widget> children;

  const _TileWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: AppSpacing.s10, runSpacing: AppSpacing.s10, children: children);
  }
}
