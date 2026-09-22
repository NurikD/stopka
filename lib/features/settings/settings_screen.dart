import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/api_key_store.dart';
import '../../core/llm/llm_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/primary_button.dart';

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

  ApiKeyStore get _store => ref.read(apiKeyStoreProvider);

  @override
  void initState() {
    super.initState();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final key = await _store.getApiKey();
    final model = await _store.getModel();
    if (!mounted) return;
    setState(() {
      _keyController.text = key ?? '';
      _model = model;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены')),
    );
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
      setState(() => _checkStatus = ok ? _KeyCheckStatus.valid : _KeyCheckStatus.invalid);
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final modelOptions = {...knownGeminiModels, _model}.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Gemini API', style: AppTypography.subtitle.copyWith(color: context.colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'Ключ Gemini API',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            onChanged: (_) => setState(() => _checkStatus = _KeyCheckStatus.idle),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _model,
            decoration: const InputDecoration(
              labelText: 'Модель',
              border: OutlineInputBorder(),
            ),
            items: modelOptions
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _model = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              PrimaryButton(label: 'Сохранить', onPressed: _save, loading: _saving),
              const SizedBox(width: AppSpacing.md),
              GhostButton(
                label: 'Проверить ключ',
                onPressed: _checkStatus == _KeyCheckStatus.checking ? null : _checkKey,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCheckStatus(context),
        ],
      ),
    );
  }

  Widget _buildCheckStatus(BuildContext context) {
    final colors = context.colors;
    switch (_checkStatus) {
      case _KeyCheckStatus.idle:
      case _KeyCheckStatus.checking:
        return const SizedBox.shrink();
      case _KeyCheckStatus.valid:
        return Text(
          'Ключ работает.',
          style: AppTypography.body.copyWith(color: colors.statusCorrect),
        );
      case _KeyCheckStatus.invalid:
        return Text(
          _checkErrorMessage ?? 'Ключ недействителен. Проверьте его и попробуйте снова.',
          style: AppTypography.body.copyWith(color: colors.statusWrong),
        );
      case _KeyCheckStatus.error:
        return Text(
          _checkErrorMessage ?? 'Не удалось проверить ключ.',
          style: AppTypography.body.copyWith(color: colors.statusWrong),
        );
    }
  }
}
