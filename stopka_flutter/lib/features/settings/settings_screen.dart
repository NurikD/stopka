import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/flags/feature_flags.dart';
import '../../core/llm/api_key_store.dart';
import '../../core/llm/llm_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/srs/srs_settings_store.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header_bar.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/segmented_choice.dart';

/// Known Gemini flash model ids as of the last documentation check
/// (ai.google.dev/gemini-api/docs/models, checked 2026-09-23). Re-verify
/// before adding new options — Google renames/retires models over time.
const List<String> knownGeminiModels = [
  'gemini-3.8-flash',
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
  'gemini-3.5-flash-lite',
];

const List<int> newCardLimitChoices = [10, 20, 30, 50];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

enum _KeyCheckStatus { idle, checking, valid, invalid, error }

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  String _model = defaultGeminiModel;
  bool _loading = true;
  bool _saving = false;
  _KeyCheckStatus _checkStatus = _KeyCheckStatus.idle;
  String? _checkErrorMessage;
  int _requestsToday = 0;
  int _newCardLimit = defaultNewCardLimit;
  List<TtsVoice> _voices = const [];
  String? _voice;
  bool _hasEnglish = true;

  ApiKeyStore get _store => ref.read(apiKeyStoreProvider);

  @override
  void initState() {
    super.initState();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final key = await _store.getApiKey();
    final model = await _store.getModel();
    final requestsToday = await ref
        .read(llmRequestCounterProvider)
        .getTodayCount();
    final newCardLimit = await ref
        .read(srsSettingsStoreProvider)
        .getNewCardLimit();
    final tts = ref.read(ttsServiceProvider);
    List<TtsVoice> voices = const [];
    var hasEnglish = true;
    String? voice;
    try {
      voices = await tts.englishVoices();
      hasEnglish = await tts.hasEnglish();
      voice = await tts.savedVoice();
    } catch (_) {
      // No speech engine on this device: the section just says so.
      hasEnglish = false;
    }
    if (!mounted) return;
    setState(() {
      _voices = voices;
      _hasEnglish = hasEnglish;
      _voice = voices.any((v) => v.name == voice) ? voice : null;
      _keyController.text = key ?? '';
      _model = model;
      _requestsToday = requestsToday;
      _newCardLimit = newCardLimit;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _store.setApiKey(_keyController.text.trim());
    await _store.setModel(_model);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
  }

  Future<void> _setNewCardLimit(int value) async {
    setState(() => _newCardLimit = value);
    await ref.read(srsSettingsStoreProvider).setNewCardLimit(value);
  }

  Future<void> _setVoice(String? name) async {
    setState(() => _voice = name);
    final tts = ref.read(ttsServiceProvider);
    await tts.saveVoice(name);
    await tts.speak('I would like to borrow a book.');
  }

  Future<void> _checkKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _checkStatus = _KeyCheckStatus.invalid;
        _checkErrorMessage = 'Сначала введите ключ.';
      });
      return;
    }
    setState(() {
      _checkStatus = _KeyCheckStatus.checking;
      _checkErrorMessage = null;
    });
    try {
      final ok = await ref.read(llmClientProvider).validateApiKey(key);
      if (!mounted) return;
      setState(
        () =>
            _checkStatus = ok ? _KeyCheckStatus.valid : _KeyCheckStatus.invalid,
      );
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _checkStatus = _KeyCheckStatus.error;
        _checkErrorMessage = e.messageRu;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Scaffold(
        appBar: AppHeaderBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final modelOptions = {...knownGeminiModels, _model}.toList();
    final limitChoices = {...newCardLimitChoices, _newCardLimit}.toList()
      ..sort();
    final themeMode = ref.watch(themeModeProvider);
    final mono = AppTypography.monoWord.copyWith(
      fontSize: 15,
      color: colors.ink,
    );

    return Scaffold(
      appBar: const AppHeaderBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s8,
          AppSpacing.screen,
          AppSpacing.s22,
        ),
        children: [
          Text(
            'Профиль',
            style: AppTypography.title.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.s22),
          AppCard(
            child: LabeledField(
              label: 'Тема',
              child: SegmentedChoice<ThemeMode>(
                options: const [
                  ChoiceOption(ThemeMode.light, 'Светлая'),
                  ChoiceOption(ThemeMode.dark, 'Тёмная'),
                  ChoiceOption(ThemeMode.system, 'Как в системе'),
                ],
                selected: themeMode,
                onChanged: (mode) =>
                    ref.read(themeModeProvider.notifier).set(mode),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          AppCard(
            child: LabeledField(
              label: 'Новых карточек за одно повторение',
              child: SegmentedChoice<int>(
                options: [for (final n in limitChoices) ChoiceOption(n, '$n')],
                selected: _newCardLimit,
                onChanged: _setNewCardLimit,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Озвучка',
                  style: AppTypography.heading.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.s14),
                if (!_hasEnglish)
                  Text(
                    'На телефоне не установлен английский голос, поэтому слова читаются с чужим акцентом. '
                    'Откройте настройки телефона → Язык и ввод → Синтез речи → Google → Установить голосовые данные → English (US).',
                    style: AppTypography.bodyText.copyWith(
                      color: colors.danger,
                    ),
                  )
                else if (_voices.isEmpty)
                  Text(
                    'Английские голоса не найдены. Голос выбирает система.',
                    style: AppTypography.bodyText.copyWith(color: colors.muted),
                  )
                else ...[
                  LabeledField(
                    label: 'Голос',
                    child: DropdownButtonFormField<String?>(
                      initialValue: _voice,
                      style: mono,
                      dropdownColor: colors.surface,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Автоматически'),
                        ),
                        for (final v in _voices)
                          DropdownMenuItem<String?>(
                            value: v.name,
                            child: Text('${v.name} · ${v.locale}'),
                          ),
                      ],
                      onChanged: _setVoice,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Выбор сразу проигрывает пример. Если звучит плохо, попробуйте другой голос.',
                    style: AppTypography.caption.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (FeatureFlags.directGemini) ...[
            const SizedBox(height: AppSpacing.s10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gemini API',
                    style: AppTypography.heading.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  LabeledField(
                    label: 'Ключ',
                    child: TextField(
                      controller: _keyController,
                      obscureText: _obscureKey,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: mono,
                      cursorColor: colors.accent,
                      decoration: InputDecoration(
                        hintText: 'Вставьте ключ',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          color: colors.muted,
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _checkStatus = _KeyCheckStatus.idle),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s14),
                  LabeledField(
                    label: 'Модель',
                    child: DropdownButtonFormField<String>(
                      initialValue: _model,
                      style: mono,
                      dropdownColor: colors.surface,
                      items: modelOptions
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _model = value);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s18),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Сохранить',
                          onPressed: _save,
                          loading: _saving,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Expanded(
                        child: GhostButton(
                          label: 'Проверить ключ',
                          onPressed: _checkStatus == _KeyCheckStatus.checking
                              ? null
                              : _checkKey,
                        ),
                      ),
                    ],
                  ),
                  _buildCheckStatus(context),
                  const SizedBox(height: AppSpacing.s14),
                  Text(
                    'Запросов к ИИ сегодня: $_requestsToday',
                    style: AppTypography.monoMeta.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckStatus(BuildContext context) {
    final colors = context.colors;
    final (String? text, Color color) = switch (_checkStatus) {
      _KeyCheckStatus.idle || _KeyCheckStatus.checking => (null, colors.muted),
      _KeyCheckStatus.valid => ('Ключ работает.', colors.success),
      _KeyCheckStatus.invalid => (
        _checkErrorMessage ??
            'Ключ недействителен. Проверьте его и попробуйте снова.',
        colors.danger,
      ),
      _KeyCheckStatus.error => (
        _checkErrorMessage ?? 'Не удалось проверить ключ.',
        colors.danger,
      ),
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s10),
      child: Text(text, style: AppTypography.bodyText.copyWith(color: color)),
    );
  }
}
