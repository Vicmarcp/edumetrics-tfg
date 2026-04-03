import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para poblar Firestore con datos de demo realistas.
/// Pensado para la defensa del TFG.
class DemoSeedService {
  static final _firestore = FirebaseFirestore.instance;
  static final _random = Random();

  // ── Datos base ──

  static const _demoStudents = [
    {
      'name': 'Lucía Martínez',
      'className': '1ºA',
      'avatarId': 1,
      'percentTarget': 82,
    },
    {
      'name': 'Diego Fernández',
      'className': '1ºA',
      'avatarId': 2,
      'percentTarget': 75,
    },
    {
      'name': 'Sofía García',
      'className': '1ºB',
      'avatarId': 3,
      'percentTarget': 88,
    },
    {
      'name': 'Hugo Rodríguez',
      'className': '1ºB',
      'avatarId': 4,
      'percentTarget': 65,
    },
    {
      'name': 'Marta López',
      'className': '1ºC',
      'avatarId': 5,
      'percentTarget': 70,
    },
  ];

  static const _activityTypes = [
    'comparison',
    'sequence',
    'place_value',
    'addition',
    'subtraction',
    'missing_vowels',
    'syllable_count',
    'sentence_order',
    'capitalization',
    'syllable_complete',
  ];

  // ── API pública ──

  /// Genera datos de demo: 5 alumnos + ~200 resultados distribuidos.
  /// Devuelve un mensaje de resumen.
  static Future<String> seedDemoData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Error: no hay sesión activa';

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final schoolId = userDoc.data()?['schoolId'] as String?;
    if (schoolId == null || schoolId.isEmpty) {
      return 'Error: el usuario no tiene schoolId configurado';
    }

    int studentsCreated = 0;
    int resultsCreated = 0;

    // Crear alumnos
    final studentIds = <String, Map<String, dynamic>>{};
    for (final s in _demoStudents) {
      final docRef = await _firestore.collection('students').add({
        'name': s['name'],
        'className': s['className'],
        'avatarId': s['avatarId'],
        'schoolId': schoolId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'parentalConsent': true,
        'isDemo': true, // Marca para poder eliminarlos después
      });
      studentIds[docRef.id] = s;
      studentsCreated++;
    }

    // Generar resultados (últimos 90 días, distribuidos)
    final now = DateTime.now();
    for (final entry in studentIds.entries) {
      final studentId = entry.key;
      final student = entry.value;
      final percentTarget = student['percentTarget'] as int;
      final className = student['className'] as String;

      // ~40 resultados por alumno, distribuidos por las 10 actividades
      for (var i = 0; i < 40; i++) {
        final activityType =
            _activityTypes[_random.nextInt(_activityTypes.length)];

        // Fecha aleatoria en los últimos 90 días, sesgada hacia el presente
        final daysAgo = (_random.nextDouble() * _random.nextDouble() * 90)
            .toInt();
        final timestamp = now.subtract(
          Duration(
            days: daysAgo,
            hours: _random.nextInt(8) + 9, // Horario lectivo
            minutes: _random.nextInt(60),
          ),
        );

        // Probabilidad de acierto según el target del alumno
        final isCorrect = _random.nextInt(100) < percentTarget;
        final timeSeconds = 1 + _random.nextInt(8); // 1-8 segundos

        final questionData = _generateQuestionData(activityType, isCorrect);

        await _firestore.collection('results').add({
          'studentId': studentId,
          'className': className,
          'schoolId': schoolId,
          'teacherId': user.uid,
          'activityType': activityType,
          'timeSeconds': timeSeconds,
          'isCorrect': isCorrect,
          'timestamp': Timestamp.fromDate(timestamp),
          'questionDetail': questionData['questionDetail'],
          'correctAnswer': questionData['correctAnswer'],
          'userAnswer': questionData['userAnswer'],
          'isDemo': true,
        });
        resultsCreated++;
      }
    }

    return 'OK: $studentsCreated alumnos y $resultsCreated resultados creados';
  }

  /// Elimina todos los datos marcados como demo.
  static Future<String> clearDemoData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Error: no hay sesión activa';

    int studentsDeleted = 0;
    int resultsDeleted = 0;

    // Eliminar resultados demo
    final demoResults = await _firestore
        .collection('results')
        .where('isDemo', isEqualTo: true)
        .get();

    var batch = _firestore.batch();
    var count = 0;
    for (final doc in demoResults.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 499) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
      resultsDeleted++;
    }
    if (count > 0) await batch.commit();

    // Eliminar alumnos demo
    final demoStudents = await _firestore
        .collection('students')
        .where('isDemo', isEqualTo: true)
        .get();

    batch = _firestore.batch();
    count = 0;
    for (final doc in demoStudents.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 499) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
      studentsDeleted++;
    }
    if (count > 0) await batch.commit();

    return 'OK: $studentsDeleted alumnos y $resultsDeleted resultados eliminados';
  }

  // ── Generación de preguntas realistas ──

  static Map<String, String> _generateQuestionData(
    String activityType,
    bool isCorrect,
  ) {
    switch (activityType) {
      case 'comparison':
        final n1 = _random.nextInt(20) + 1;
        var n2 = _random.nextInt(20) + 1;
        while (n2 == n1) {
          n2 = _random.nextInt(20) + 1;
        }
        final correct = n1 > n2 ? 'mayor' : 'menor';
        return {
          'questionDetail': '$n1 vs $n2',
          'correctAnswer': correct,
          'userAnswer': isCorrect
              ? correct
              : (correct == 'mayor' ? 'menor' : 'mayor'),
        };

      case 'sequence':
        final mid = _random.nextInt(18) + 2;
        return {
          'questionDetail': '${mid - 1}, ?, ${mid + 1}',
          'correctAnswer': mid.toString(),
          'userAnswer': isCorrect ? mid.toString() : (mid + 1).toString(),
        };

      case 'place_value':
        final n = _random.nextInt(11) + 10;
        final askTens = _random.nextBool();
        final correct = askTens ? n ~/ 10 : n % 10;
        return {
          'questionDetail': '$n: ¿${askTens ? "Decenas" : "Unidades"}?',
          'correctAnswer': correct.toString(),
          'userAnswer': isCorrect
              ? correct.toString()
              : ((correct + 1) % 10).toString(),
        };

      case 'addition':
        final a = _random.nextInt(10) + 1;
        final b = _random.nextInt(20 - a) + 1;
        return {
          'questionDetail': '$a + $b',
          'correctAnswer': (a + b).toString(),
          'userAnswer': isCorrect ? (a + b).toString() : (a + b + 1).toString(),
        };

      case 'subtraction':
        final a = _random.nextInt(19) + 2;
        final b = _random.nextInt(a) + 1;
        return {
          'questionDetail': '$a − $b',
          'correctAnswer': (a - b).toString(),
          'userAnswer': isCorrect ? (a - b).toString() : (a - b - 1).toString(),
        };

      case 'missing_vowels':
        final words = [
          {'word': 'CASA', 'vowel': 'A', 'display': 'C_SA'},
          {'word': 'GATO', 'vowel': 'A', 'display': 'G_TO'},
          {'word': 'LUNA', 'vowel': 'U', 'display': 'L_NA'},
          {'word': 'MESA', 'vowel': 'E', 'display': 'M_SA'},
          {'word': 'LIBRO', 'vowel': 'I', 'display': 'L_BRO'},
        ];
        final w = words[_random.nextInt(words.length)];
        return {
          'questionDetail': '${w['display']} (${w['word']})',
          'correctAnswer': w['vowel']!,
          'userAnswer': isCorrect ? w['vowel']! : 'O',
        };

      case 'syllable_count':
        final words = [
          {'word': 'CASA', 'syllables': 2},
          {'word': 'PAN', 'syllables': 1},
          {'word': 'CONEJO', 'syllables': 3},
          {'word': 'MARIPOSA', 'syllables': 4},
          {'word': 'GATO', 'syllables': 2},
        ];
        final w = words[_random.nextInt(words.length)];
        final correct = w['syllables'].toString();
        return {
          'questionDetail': '${w['word']}: ¿cuántas sílabas?',
          'correctAnswer': correct,
          'userAnswer': isCorrect
              ? correct
              : ((w['syllables'] as int) + 1).toString(),
        };

      case 'sentence_order':
        final sentences = [
          'El gato bebe agua',
          'Mi perro es grande',
          'La luna sale hoy',
          'Yo como pan',
          'La rana salta mucho',
        ];
        final s = sentences[_random.nextInt(sentences.length)];
        return {
          'questionDetail': s,
          'correctAnswer': s,
          'userAnswer': isCorrect ? s : s.split(' ').reversed.join(' '),
        };

      case 'capitalization':
        final cases = [
          {'sentence': 'el gato duerme', 'word': 'el', 'rule': 'inicio'},
          {'sentence': 'yo soy maria', 'word': 'maria', 'rule': 'nombre'},
          {'sentence': 'mi amigo pedro', 'word': 'pedro', 'rule': 'nombre'},
        ];
        final c = cases[_random.nextInt(cases.length)];
        return {
          'questionDetail':
              '${c['sentence']} (${c['rule'] == 'inicio' ? "inicio de frase" : "nombre propio"})',
          'correctAnswer': c['word']!,
          'userAnswer': isCorrect
              ? c['word']!
              : (c['sentence'] as String).split(' ').first,
        };

      case 'syllable_complete':
        final cases = [
          {'visible': 'CA-?', 'full': 'CA-SA', 'correct': 'SA'},
          {'visible': '?-TO', 'full': 'GA-TO', 'correct': 'GA'},
          {'visible': 'LU-?', 'full': 'LU-NA', 'correct': 'NA'},
        ];
        final c = cases[_random.nextInt(cases.length)];
        return {
          'questionDetail': '${c['visible']} (${c['full']})',
          'correctAnswer': c['correct']!,
          'userAnswer': isCorrect ? c['correct']! : 'TO',
        };

      default:
        return {'questionDetail': '', 'correctAnswer': '', 'userAnswer': ''};
    }
  }
}
