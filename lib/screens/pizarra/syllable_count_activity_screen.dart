import 'dart:math';

import 'package:flutter/material.dart';

import 'base_activity_screen.dart';

class SyllableCountActivityScreen extends BaseActivityScreen {
  const SyllableCountActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'syllable_count');

  @override
  State<SyllableCountActivityScreen> createState() =>
      _SyllableCountActivityState();
}

class _SyllableCountActivityState
    extends BaseActivityState<SyllableCountActivityScreen> {
  // Palabra y su número de sílabas
  final List<Map<String, dynamic>> _wordBank = [
    // 1 sílaba
    {'word': 'SOL', 'syllables': 1},
    {'word': 'PAN', 'syllables': 1},
    {'word': 'MAR', 'syllables': 1},
    {'word': 'LUZ', 'syllables': 1},
    {'word': 'FLOR', 'syllables': 1},
    {'word': 'TREN', 'syllables': 1},
    {'word': 'PEZ', 'syllables': 1},
    // 2 sílabas
    {'word': 'CASA', 'syllables': 2},
    {'word': 'MESA', 'syllables': 2},
    {'word': 'GATO', 'syllables': 2},
    {'word': 'LUNA', 'syllables': 2},
    {'word': 'PATO', 'syllables': 2},
    {'word': 'RANA', 'syllables': 2},
    {'word': 'LOBO', 'syllables': 2},
    {'word': 'NUBE', 'syllables': 2},
    {'word': 'DADO', 'syllables': 2},
    {'word': 'BOCA', 'syllables': 2},
    // 3 sílabas
    {'word': 'CONEJO', 'syllables': 3},
    {'word': 'ZAPATO', 'syllables': 3},
    {'word': 'PIRATA', 'syllables': 3},
    {'word': 'COMETA', 'syllables': 3},
    {'word': 'COCINA', 'syllables': 3},
    {'word': 'HELADO', 'syllables': 3},
    {'word': 'PALOMA', 'syllables': 3},
    {'word': 'CABALLO', 'syllables': 3},
    {'word': 'NARANJA', 'syllables': 3},
    {'word': 'TORTUGA', 'syllables': 3},
    // 4 sílabas
    {'word': 'MARIPOSA', 'syllables': 4},
    {'word': 'ELEFANTE', 'syllables': 4},
    {'word': 'CASTILLO', 'syllables': 3},
    {'word': 'ESTRELLA', 'syllables': 3},
    {'word': 'VENTANA', 'syllables': 3},
    {'word': 'GALLINA', 'syllables': 3},
    {'word': 'CHOCOLATE', 'syllables': 4},
    {'word': 'DINOSAURIO', 'syllables': 4},
    {'word': 'BICICLETA', 'syllables': 4},
    {'word': 'CALABAZA', 'syllables': 4},
    {'word': 'COCODRILO', 'syllables': 4},
  ];

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_wordBank)
      ..shuffle(random);
    return shuffled.take(totalQuestions).toList();
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final word = question['word'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¿Cuántas sílabas tiene?',
          style: TextStyle(
            fontSize: 28,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo, width: 3),
          ),
          child: Text(
            word,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
              letterSpacing: 8,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [1, 2, 3, 4].map((number) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () => handleAnswer(number),
            style: ElevatedButton.styleFrom(
              backgroundColor: _numberColor(number),
              foregroundColor: Colors.white,
              fixedSize: const Size(100, 100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer) {
    return userAnswer == question['syllables'];
  }

  Color _numberColor(int number) {
    switch (number) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}