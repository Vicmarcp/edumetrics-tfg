import 'package:posthog_flutter/posthog_flutter.dart';

/// Wrapper sobre PostHog para analytics de producto.
///
/// REGLAS DE PRIVACIDAD (no negociables):
/// - Solo se identifica al PROFESOR por su uid de Firebase. Nunca email ni nombre.
/// - NUNCA enviar datos de alumnos (ni nombres, ni ids) en eventos o propiedades.
///   Los eventos sobre actividades se registran de forma agregada y anónima:
///   "actividad completada", no "el alumno X completó la actividad".
///
/// Todas las llamadas van envueltas en try/catch: los analytics no deben
/// romper la app ni los tests bajo ninguna circunstancia.
class PosthogService {
  PosthogService._();

  static String? _lastIdentifiedUid;

  /// Asocia los eventos de esta sesión al profesor logueado.
  /// Idempotente: llamadas repetidas con el mismo uid no hacen nada.
  static Future<void> identify(String uid) async {
    if (_lastIdentifiedUid == uid) return;
    _lastIdentifiedUid = uid;
    try {
      await Posthog().identify(userId: uid);
    } catch (_) {
      // Silencioso a propósito: analytics nunca rompe la app.
    }
  }

  /// Desvincula la identidad al cerrar sesión.
  static Future<void> reset() async {
    _lastIdentifiedUid = null;
    try {
      await Posthog().reset();
    } catch (_) {}
  }

  /// Registra un evento de negocio con propiedades opcionales.
  /// Ejemplo: capture('actividad_completada', properties: {'tipo': 'sumas'})
  static Future<void> capture(
      String event, {
        Map<String, Object>? properties,
      }) async {
    try {
      await Posthog().capture(eventName: event, properties: properties);
    } catch (_) {}
  }
}