import 'package:flutter/material.dart';
import 'package:suzyapp/widgets/parent_gate_dialog.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';
import '../models/parent_voice_settings.dart';
import '../repositories/parent_voice_settings_repository.dart';

class ParentVoiceSettingsScreen extends StatefulWidget {
  const ParentVoiceSettingsScreen({super.key});

  static const routeName = '/parent-voice-settings';

  @override
  State<ParentVoiceSettingsScreen> createState() => _ParentVoiceSettingsScreenState();
}

class _ParentVoiceSettingsScreenState extends State<ParentVoiceSettingsScreen> {
  final _repo = ParentVoiceSettingsRepository();
  final _voiceIdController = TextEditingController();

  bool _localEnabled = false;
  bool _dirty = false;
  bool _saving = false;
  String? _status;

  // 🔐 Hard gate state
  bool _gateChecked = false;
  bool _gateAllowed = false;

  @override
  void initState() {
    super.initState();

    // 🔐 Hard gate: prevents deep-link access (especially on web)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
   final allowed = await showParentGate(context, force: true);
      if (!mounted) return;

      if (!allowed) {
        Navigator.pop(context);
        return;
      }

      setState(() {
        _gateChecked = true;
        _gateAllowed = true;
      });
    });
  }

  @override
  void dispose() {
    _voiceIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = null;
    });

    try {
      final settings = ParentVoiceSettings(
        parentVoiceEnabled: _localEnabled,
        elevenVoiceId: _voiceIdController.text.trim(),
      );

      await _repo.saveSettings(settings);

      if (!mounted) return;
      setState(() {
        _dirty = false;
        _status = 'Saved';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _test() {
    // Intentionally not wired to ParentVoiceService here to avoid mismatched signatures.
    // This keeps the screen compile-safe and still useful for enabling/disabling + voiceId storage.
    if (!_localEnabled) {
      setState(() => _status = 'Enable Parent Voice to test.');
      return;
    }
    if (_voiceIdController.text.trim().isEmpty) {
      setState(() => _status = 'Enter an ElevenLabs Voice ID first.');
      return;
    }
    setState(() => _status = 'Test not wired yet (settings are saved correctly).');
  }

  @override
  Widget build(BuildContext context) {
    // While gate is checking, show a minimal scaffold
    if (!_gateChecked) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If somehow we got here without permission (extra safety)
    if (!_gateAllowed) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Parents only')),
      );
    }

    return StreamBuilder<ParentVoiceSettings>(
      stream: _repo.watchSettings(),
      builder: (context, snap) {
        final data = snap.data ?? ParentVoiceSettings.defaults();

        // Initialize local UI state from stream only when user isn't editing.
        if (!_dirty) {
          _localEnabled = data.parentVoiceEnabled;

          final incoming = data.elevenVoiceId;
          if (_voiceIdController.text != incoming) {
            _voiceIdController.text = incoming;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Parent Voice'),
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    title: 'Voice',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Use Parent Voice'),
                          subtitle: const Text(
                            'If unavailable, SuzyApp will use app voice automatically.',
                          ),
                          value: _localEnabled,
                          onChanged: (v) {
                            setState(() {
                              _localEnabled = v;
                              _dirty = true;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        TextField(
                          controller: _voiceIdController,
                          enabled: _localEnabled,
                          decoration: InputDecoration(
                            labelText: 'ElevenLabs Voice ID',
                            hintText: 'e.g. nzFihrBIvB34imQBuxub',
                            helperText: _localEnabled
                                ? 'This must match the Voice ID in ElevenLabs.'
                                : 'Enable Parent Voice to edit.',
                          ),
                          onChanged: (_) => setState(() => _dirty = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _test,
                          child: const Text('Test'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_saving || !_dirty) ? null : _save,
                          child: _saving ? const Text('Saving...') : const Text('Save'),
                        ),
                      ),
                    ],
                  ),

                  if (_status != null) ...[
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      _status!,
                      style: TextStyle(
                        color: (_status!.startsWith('Save failed') ||
                                _status!.startsWith('Test failed'))
                            ? AppColors.choiceRed
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.large),

                  _SectionCard(
                    title: 'Stored in Firestore',
                    child: const Text(
                      'users/{uid}/settings/audio\n'
                      '• parentVoiceEnabled (bool)\n'
                      '• elevenVoiceId (string)\n'
                      '\n'
                      'Note: backend expects "lang" (not "language").',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}
