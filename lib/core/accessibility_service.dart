import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Servicio de accesibilidad global.
/// Gestiona tamaño de fuente, modo dislexia y sonidos.
class AccessibilityService {
  // ── Tamaño de fuente ──
  static final ValueNotifier<double> fontScale = ValueNotifier(1.0);

  /// Valores permitidos: 0.85 (pequeño), 1.0 (normal), 1.2 (grande)
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

  static String get fontFamily => dyslexicFont.value ? 'OpenDyslexic' : '';

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
}
