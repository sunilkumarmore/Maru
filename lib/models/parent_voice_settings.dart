class ParentVoiceSettings {
  final bool parentVoiceEnabled;
  final String elevenVoiceId;
  final Map<String, dynamic> elevenlabsSettings;

  const ParentVoiceSettings({
    required this.parentVoiceEnabled,
    required this.elevenVoiceId,
    required this.elevenlabsSettings,
  });

  factory ParentVoiceSettings.defaults() => const ParentVoiceSettings(
        parentVoiceEnabled: false,
        elevenVoiceId: '',
        elevenlabsSettings: {
          'stability': 0.35,
          'similarity_boost': 0.80,
          'style': 0.60,
          'use_speaker_boost': true,
          'speed': 0.9,
        },
      );

  ParentVoiceSettings copyWith({
    bool? parentVoiceEnabled,
    String? elevenVoiceId,
    Map<String, dynamic>? elevenlabsSettings,
  }) {
    return ParentVoiceSettings(
      parentVoiceEnabled: parentVoiceEnabled ?? this.parentVoiceEnabled,
      elevenVoiceId: elevenVoiceId ?? this.elevenVoiceId,
      elevenlabsSettings: elevenlabsSettings ?? this.elevenlabsSettings,
    );
  }
}
