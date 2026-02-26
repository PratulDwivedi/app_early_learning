import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/speech_settings_provider.dart';

class SpeechService {
  SpeechService() : _tts = FlutterTts();

  final FlutterTts _tts;

  Future<void> speak(String text, SpeechSettingsState settings) async {
    final content = text.trim();
    if (content.isEmpty) return;

    await _tts.stop();
    await _tts.setLanguage(settings.language);
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.pitch);
    await _tts.setVolume(settings.volume);
    await _tts.speak(content);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(() {
    service.stop();
  });
  return service;
});
