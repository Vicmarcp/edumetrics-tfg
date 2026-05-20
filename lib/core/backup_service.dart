import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;

import 'audit_service.dart';

/// Servicio de copia de seguridad y portabilidad de datos del centro.
/// Cumple el Art. 20 RGPD (derecho a la portabilidad).
class BackupService {
  static final _firestore = FirebaseFirestore.instance;

  /// Exporta TODOS los datos del centro (alumnos + resultados) en JSON
  /// estructurado y legible. Solo accesible al profesor del centro.
  static Future<String> exportFullBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Error: no hay sesión activa';

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final schoolId = userDoc.data()?['schoolId'] as String?;
    if (schoolId == null || schoolId.isEmpty) {
      return 'Error: el usuario no tiene schoolId configurado';
    }

    try {
      // Obtener alumnos del centro
      final studentsSnap = await _firestore
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      // Obtener resultados del centro
      final resultsSnap = await _firestore
          .collection('results')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      // Estructurar datos
      final backup = {
        'metadata': {
          'app': 'EduMetrics',
          'version': '1.0.0',
          'exportedAt': DateTime.now().toIso8601String(),
          'exportedBy': user.email,
          'schoolId': schoolId,
          'rgpdNotice':
              'Este archivo contiene datos personales en virtud del Art. 20 RGPD '
              '(derecho a la portabilidad). Custódielo con la debida diligencia y '
              'elimínelo cuando no sea necesario.',
        },
        'summary': {
          'totalStudents': studentsSnap.docs.length,
          'totalResults': resultsSnap.docs.length,
          'activeStudents': studentsSnap.docs
              .where((d) => d.data()['isActive'] == true)
              .length,
        },
        'students': studentsSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'name': d['name'],
            'className': d['className'],
            'avatarId': d['avatarId'],
            'isActive': d['isActive'] ?? true,
            'parentalConsent': d['parentalConsent'] ?? false,
            'createdAt': _formatTimestamp(d['createdAt']),
          };
        }).toList(),
        'results': resultsSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'studentId': d['studentId'],
            'className': d['className'],
            'activityType': d['activityType'],
            'isCorrect': d['isCorrect'],
            'timeSeconds': d['timeSeconds'],
            'questionDetail': d['questionDetail'] ?? '',
            'correctAnswer': d['correctAnswer'] ?? '',
            'userAnswer': d['userAnswer'] ?? '',
            'timestamp': _formatTimestamp(d['timestamp']),
          };
        }).toList(),
      };

      // Convertir a JSON formateado
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(backup);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Descargar
      final filename =
          'edumetrics_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
      _downloadFile(bytes, filename, 'application/json');

      // Auditoría
      await AuditService.log(
        action: 'export_full_backup',
        targetId: schoolId,
        details: {
          'totalStudents': studentsSnap.docs.length,
          'totalResults': resultsSnap.docs.length,
        },
      );

      return 'OK: backup generado con ${studentsSnap.docs.length} alumnos '
          'y ${resultsSnap.docs.length} resultados';
    } catch (_) {
      return 'Error al generar el backup. Inténtalo de nuevo.';
    }
  }

  static String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return ts.toDate().toIso8601String();
    }
    return ts?.toString() ?? '';
  }

  static void _downloadFile(Uint8List bytes, String filename, String mimeType) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
