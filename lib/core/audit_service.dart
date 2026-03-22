import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de auditoría que registra todas las acciones sobre datos
/// de alumnos y resultados para cumplimiento RGPD y trazabilidad.
class AuditService {
  static final _collection =
  FirebaseFirestore.instance.collection('audit_logs');

  /// Registra una acción en el log de auditoría.
  ///
  /// [action] — tipo de acción: create_student, update_student,
  ///   deactivate_student, delete_student, delete_results,
  ///   delete_account, export_data
  /// [targetId] — ID del documento afectado
  /// [details] — información adicional (nombre, clase, etc.)
  static Future<void> log({
    required String action,
    required String targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _collection.add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'action': action,
        'targetId': targetId,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Error silencioso — el log de auditoría no debe interrumpir
      // la operación principal del usuario
    }
  }
}