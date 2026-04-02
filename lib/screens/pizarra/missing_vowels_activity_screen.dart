import 'dart:math';

import 'package:flutter/material.dart';

import 'base_activity_screen.dart';

class MissingVowelsActivityScreen extends BaseActivityScreen {
  const MissingVowelsActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'missing_vowels');

  @override
  State<MissingVowelsActivityScreen> createState() =>
      _MissingVowelsActivityState();
}

class _MissingVowelsActivityState
    extends BaseActivityState<MissingVowelsActivityScreen> {
  // Banco de palabras sencillas para 1º-2º primaria
  final List<String> _wordBank = [
    'CASA',
    'MESA',
    'GATO',
    'PERRO',
    'LUNA',
    'SOLE',
    'AGUA',
    'PATO',
    'RANA',
    'LOBO',
    'MANO',
    'DEDO',
    'PELO',
    'BOCA',
    'ROJO',
    'AZUL',
    'ROSA',
    'NIDO',
    'CAMA',
    'SOPA',
    'VACA',
    'MONO',
    'OSO',
    'PERA',
    'MAPA',
    'LUPA',
    'NUBE',
    'REMO',
    'FOCA',
    'DADO',
    'HOJA',
    'BESO',
    'TAZA',
    'SILLA',
    'LIBRO',
    'PLUMA',
    'TIGRE',
    'GLOBO',
    'FRUTA',
    'ARBOL',
    'ABEJA',
    'AMIGO',
    'BARCO',
    'BRUJA',
    'CAMPO',
    'CIELO',
    'DUENDE',
    'ELEFANTE',
    'ESCUELA',
    'ESTRELLA',
    'GALLINA',
    'HELADO',
    'IGLESIA',
    'JIRAFA',
    'MARIPOSA',
    'NARANJA',
    'OTOÑO',
    'PAJARO',
    'PALOMA',
    'CONEJO',
    'BALLENA',
    'CABALLO',
    'CASTILLO',
    'COCINA',
    'COMETA',
    'DRAGÓN',
    'TORTUGA',
    'VENTANA',
    'ZAPATO',
    'PIRATA',
  ];

  static const List<String> _vowels = ['A', 'E', 'I', 'O', 'U'];

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    final shuffled = List<String>.from(_wordBank)..shuffle(random);
    final selected = shuffled.take(totalQuestions).toList();

    return selected.map((word) {
      // Encontrar posiciones de vocales en la palabra
      final vowelPositions = <int>[];
      for (int i = 0; i < word.length; i++) {
        if (_vowels.contains(word[i])) {
          vowelPositions.add(i);
        }
      }

      // Elegir una vocal aleatoria para ocultar
      final hiddenIndex = vowelPositions[random.nextInt(vowelPositions.length)];
      final hiddenVowel = word[hiddenIndex];

      // Construir la palabra con hueco
      final displayWord = '${word.substring(0, hiddenIndex)}_${word.substring(hiddenIndex + 1)}';

      return {
        'word': word,
        'displayWord': displayWord,
        'hiddenVowel': hiddenVowel,
        'hiddenIndex': hiddenIndex,
        'correctAnswer': hiddenVowel,
      };
    }).toList();
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta palabra:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _exampleLetter('G', false),
          _exampleLetter('_', true),
          _exampleLetter('T', false),
          _exampleLetter('O', false),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text('La palabra es GATO\nFalta la vocal A ✓',
              style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _exampleLetter(String letter, bool isHidden) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 70, height: 80,
        decoration: BoxDecoration(
          color: isHidden ? Colors.orange.withValues(alpha: 0.15) : Colors.blue
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isHidden ? Colors.orange : Colors.blue,
              width: isHidden ? 4 : 2),
        ),
        child: Center(child: Text(letter, style: TextStyle(fontSize: 44,
            fontWeight: FontWeight.bold,
            color: isHidden ? Colors.orange : Colors.blue.shade700))),
      ),
    );
  }

  @override
  String getTutorialHint() => 'Elige la vocal que falta en la palabra';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    return '${question['displayWord']} (${question['word']})';
  }
  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final displayWord = question['displayWord'] as String;
    final hiddenIndex = question['hiddenIndex'] as int;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(displayWord.length, (i) {
        final isHidden = i == hiddenIndex;
        final letter = displayWord[i];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              color: isHidden
                  ? Colors.orange.withValues(alpha: 0.15)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHidden ? Colors.orange : Colors.blue,
                width: isHidden ? 4 : 2,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: isHidden ? Colors.orange : Colors.blue.shade700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _vowels.map((vowel) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ElevatedButton(
            onPressed: () => handleAnswer(vowel),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vowelColor(vowel),
              foregroundColor: Colors.white,
              fixedSize: const Size(90, 90),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            child: Text(
              vowel,
              style: const TextStyle(
                fontSize: 44,
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
    return userAnswer.toString() == question['hiddenVowel'];
  }

  Color _vowelColor(String vowel) {
    switch (vowel) {
      case 'A':
        return Colors.red;
      case 'E':
        return Colors.green;
      case 'I':
        return Colors.blue;
      case 'O':
        return Colors.purple;
      case 'U':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}