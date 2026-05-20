import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de accesibilidad global.
/// Gestiona: fuente dislexia, tamaño texto, sonidos, narración,
/// alto contraste y modo daltónico.
class AccessibilityService {
  // ── Tamaño de fuente ──
  static final ValueNotifier<double> fontScale = ValueNotifier(1.0);

  static void setFontSize(String size) {
    switch (size) {
      case 'small':
        fontScale.value = 0.85;
        break;
      case 'large':
        fontScale.value = 1.2;
        break;
      default:
        fontScale.value = 1.0;
    }
  }

  static String get currentFontSizeLabel {
    if (fontScale.value < 0.9) return 'small';
    if (fontScale.value > 1.1) return 'large';
    return 'normal';
  }

  // ── Fuente para dislexia ──
  static final ValueNotifier<bool> dyslexicFont = ValueNotifier(false);

  // ── Sonidos ──
  static final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playCorrect() async {
    if (!soundEnabled.value) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/correct.mp3'));
    } catch (_) {}
  }

  static Future<void> playError() async {
    if (!soundEnabled.value) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (_) {}
  }

  // ── Narración por voz (TTS) ──
  static final ValueNotifier<bool> ttsEnabled = ValueNotifier(false);
  static final FlutterTts _tts = FlutterTts();
  static bool _ttsInitialized = false;
  static bool _isSpeaking = false;

  // Regex para eliminar emojis del texto antes de enviarlo al sintetizador
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|'
    r'[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|'
    r'[\u{FE00}-\u{FE0F}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|'
    r'[\u{1FA70}-\u{1FAFF}]|[\u{200D}]|[\u{20E3}]|[\u{E0020}-\u{E007F}]',
    unicode: true,
  );

  static String _cleanForTts(String text) {
    return text
        .replaceAll(_emojiRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<void> _initTts() async {
    if (_ttsInitialized) return;
    try {
      await _tts.awaitSpeakCompletion(false);
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.55);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);
      _ttsInitialized = true;
    } catch (_) {}
  }

  /// Para y espera a que Chrome libere el sintetizador.
  static Future<void> _stopAndWaitReady() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
    // Chrome necesita ~200ms tras cancel() para aceptar otra utterance
    await Future.delayed(const Duration(milliseconds: 200));
  }

  static Future<void> speak(String text) async {
    if (!ttsEnabled.value || text.isEmpty) return;
    await _initTts();
    final clean = _cleanForTts(text);
    if (clean.isEmpty) return;
    try {
      await _stopAndWaitReady();
      _isSpeaking = true;
      await _tts.speak(clean);
    } catch (_) {
      _isSpeaking = false;
    }
  }

  static Future<void> speakAndWait(String text) async {
    if (!ttsEnabled.value || text.isEmpty) return;
    await _initTts();
    final clean = _cleanForTts(text);
    if (clean.isEmpty) return;
    try {
      await _stopAndWaitReady();
      _isSpeaking = true;
      await _tts.speak(clean);
      // Gracia inicial: dejar que el motor arranque (o falle) antes de sondear
      await Future.delayed(const Duration(milliseconds: 250));
      // Esperar a que termine (polling compatible con web)
      final maxWait = clean.length * 100 + 2000;
      var waited = 0;
      while (_isSpeaking && waited < maxWait) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
    } catch (_) {
      _isSpeaking = false;
    }
  }

  static Future<void> stopSpeaking() async {
    await _stopAndWaitReady();
  }

  // ── Alto contraste ──
  static final ValueNotifier<bool> highContrast = ValueNotifier(false);

  /// Grosor de borde adaptado al modo
  static double get borderWidth => highContrast.value ? 5.0 : 2.0;

  /// Grosor de borde grueso (para elementos destacados)
  static double get thickBorderWidth => highContrast.value ? 7.0 : 4.0;

  // ── Modo daltónico ──
  static final ValueNotifier<bool> colorblindMode = ValueNotifier(false);

  /// Colores seguros para daltónicos (paleta Wong)
  /// Sustituyen verde/rojo por azul/naranja
  static Color get correctColor =>
      colorblindMode.value ? const Color(0xFF0072B2) : Colors.green;

  static Color get errorColor =>
      colorblindMode.value ? const Color(0xFFD55E00) : Colors.red;

  static Color get correctColorLight => colorblindMode.value
      ? const Color(0xFF0072B2).withValues(alpha: 0.15)
      : Colors.green.shade100;

  static Color get errorColorLight => colorblindMode.value
      ? const Color(0xFFD55E00).withValues(alpha: 0.15)
      : Colors.red.shade100;

  /// Paleta de colores para gráficas (segura para daltónicos)
  static List<Color> get chartColors => colorblindMode.value
      ? const [
          Color(0xFF0072B2), // Azul
          Color(0xFFE69F00), // Amarillo
          Color(0xFF009E73), // Verde azulado
          Color(0xFFCC79A7), // Rosa
          Color(0xFF56B4E9), // Azul claro
          Color(0xFFD55E00), // Naranja
          Color(0xFF000000), // Negro
          Color(0xFF0072B2), // Azul (repite)
          Color(0xFFE69F00), // Amarillo (repite)
          Color(0xFF009E73), // Verde azulado (repite)
        ]
      : [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.teal,
          Colors.indigo,
          Colors.cyan,
          Colors.deepPurple,
          Colors.amber,
        ];

  /// Color para barras de gráfica según porcentaje
  static Color chartBarColor(double percent) {
    if (colorblindMode.value) {
      if (percent >= 70) return const Color(0xFF0072B2); // Azul
      if (percent >= 50) return const Color(0xFFE69F00); // Amarillo
      return const Color(0xFFD55E00); // Naranja
    }
    if (percent >= 70) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }
}