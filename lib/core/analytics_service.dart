import 'package:firebase_analytics/firebase_analytics.dart';

/// Servicio de analytics. Registra eventos clave de la app
/// para entender uso real y detectar fricciones.
/// No registra datos personales — solo eventos agregados.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Eventos de actividad ──

  static Future<void> activityStarted(String activityType) async {
    try {
      await _analytics.logEvent(
        name: 'activity_started',
        parameters: {'activity_type': activityType},
      );
    } catch (_) {}
  }

  static Future<void> activityCompleted({
    required String activityType,
    required int correctAnswers,
    required int totalQuestions,
    required int durationSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'activity_completed',
        parameters: {
          'activity_type': activityType,
          'correct': correctAnswers,
          'total': totalQuestions,
          'percent': (correctAnswers * 100 / totalQuestions).round(),
          'duration_seconds': durationSeconds,
        },
      );
    } catch (_) {}
  }

  // ── Eventos de exportación ──

  static Future<void> exportPerformed({
    required String
    type, // 'student_excel', 'student_pdf', 'class_excel', 'class_pdf'
    required int recordCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'export_performed',
        parameters: {'type': type, 'record_count': recordCount},
      );
    } catch (_) {}
  }

  // ── Eventos de accesibilidad ──

  static Future<void> accessibilityToggled({
    required String feature, // 'tts', 'dyslexic', 'high_contrast', 'colorblind'
    required bool enabled,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'accessibility_toggled',
        parameters: {'feature': feature, 'enabled': enabled ? 1 : 0},
      );
    } catch (_) {}
  }

  // ── Errores ──

  static Future<void> loginError(String reason) async {
    try {
      await _analytics.logEvent(
        name: 'login_error',
        parameters: {'reason': reason},
      );
    } catch (_) {}
  }

  // ── Sesiones ──

  static Future<void> sessionStarted(String mode) async {
    try {
      await _analytics.logEvent(
        name: 'session_started',
        parameters: {'mode': mode}, // 'pizarra' o 'desktop'
      );
    } catch (_) {}
  }
}
