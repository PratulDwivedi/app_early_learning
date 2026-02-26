import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechSettingsState {
  final String language;
  final double speechRate;
  final double pitch;
  final double volume;
  final bool isLoaded;

  const SpeechSettingsState({
    this.language = 'en-US',
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 0.8,
    this.isLoaded = false,
  });

  SpeechSettingsState copyWith({
    String? language,
    double? speechRate,
    double? pitch,
    double? volume,
    bool? isLoaded,
  }) {
    return SpeechSettingsState(
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SpeechSettingsNotifier extends StateNotifier<SpeechSettingsState> {
  SpeechSettingsNotifier() : super(const SpeechSettingsState()) {
    _load();
  }

  static const _languageKey = 'speech_language';
  static const _rateKey = 'speech_rate';
  static const _pitchKey = 'speech_pitch';
  static const _volumeKey = 'speech_volume';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      language: prefs.getString(_languageKey) ?? state.language,
      speechRate: prefs.getDouble(_rateKey) ?? state.speechRate,
      pitch: prefs.getDouble(_pitchKey) ?? state.pitch,
      volume: prefs.getDouble(_volumeKey) ?? state.volume,
      isLoaded: true,
    );
  }

  Future<void> setLanguage(String value) async {
    state = state.copyWith(language: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
  }

  Future<void> setSpeechRate(double value) async {
    state = state.copyWith(speechRate: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, value);
  }

  Future<void> setPitch(double value) async {
    state = state.copyWith(pitch: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pitchKey, value);
  }

  Future<void> setVolume(double value) async {
    state = state.copyWith(volume: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value);
  }
}

final speechSettingsProvider =
    StateNotifierProvider<SpeechSettingsNotifier, SpeechSettingsState>((ref) {
  return SpeechSettingsNotifier();
});
