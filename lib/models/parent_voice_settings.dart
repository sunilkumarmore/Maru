class ParentVoiceSettings {
  final bool parentVoiceEnabled;
  final String elevenVoiceId;

  const ParentVoiceSettings({
    required this.parentVoiceEnabled,
    required this.elevenVoiceId,
  });

  factory ParentVoiceSettings.defaults() =>
      const ParentVoiceSettings(parentVoiceEnabled: false, elevenVoiceId: '');

  ParentVoiceSettings copyWith({
    bool? parentVoiceEnabled,
    String? elevenVoiceId,
  }) {
    return ParentVoiceSettings(
      parentVoiceEnabled: parentVoiceEnabled ?? this.parentVoiceEnabled,
      elevenVoiceId: elevenVoiceId ?? this.elevenVoiceId,
    );
  }
}
