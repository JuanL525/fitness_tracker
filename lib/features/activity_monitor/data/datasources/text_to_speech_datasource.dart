import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

abstract class TextToSpeechDataSource {
  Future<void> initialize();
  Future<void> speak(String message);
}

class TextToSpeechDataSourceImpl implements TextToSpeechDataSource {
  TextToSpeechDataSourceImpl({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _setLanguageFromSystem();
    _initialized = true;
  }

  Future<void> _setLanguageFromSystem() async {
    final locale = Platform.localeName.replaceAll('_', '-');
    final available = await _tts.isLanguageAvailable(locale);
    if (available == true) {
      await _tts.setLanguage(locale);
      return;
    }

    const fallbacks = ['es-ES', 'es-MX', 'en-US'];
    for (final language in fallbacks) {
      if (await _tts.isLanguageAvailable(language) == true) {
        await _tts.setLanguage(language);
        return;
      }
    }
  }

  @override
  Future<void> speak(String message) async {
    if (!_initialized) {
      await initialize();
    }
    await _tts.stop();
    await _tts.speak(message);
  }
}
