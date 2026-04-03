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
  final List<Map<String, String>> _wordBank = [
    {'word': 'CASA', 'emoji': '🏠', 'hint': 'Donde vivimos'},
    {'word': 'MESA', 'emoji': '🪑', 'hint': 'Donde comemos'},
    {'word': 'GATO', 'emoji': '🐱', 'hint': 'Animal que maúlla'},
    {'word': 'PERRO', 'emoji': '🐶', 'hint': 'Animal que ladra'},
    {'word': 'LUNA', 'emoji': '🌙', 'hint': 'Brilla de noche'},
    {'word': 'AGUA', 'emoji': '💧', 'hint': 'La bebemos'},
    {'word': 'PATO', 'emoji': '🦆', 'hint': 'Ave que nada'},
    {'word': 'RANA', 'emoji': '🐸', 'hint': 'Salta y croa'},
    {'word': 'LOBO', 'emoji': '🐺', 'hint': 'Aúlla a la luna'},
    {'word': 'MANO', 'emoji': '✋', 'hint': 'Tiene cinco dedos'},
    {'word': 'DEDO', 'emoji': '👆', 'hint': 'Parte de la mano'},
    {'word': 'PELO', 'emoji': '💇', 'hint': 'Crece en la cabeza'},
    {'word': 'BOCA', 'emoji': '👄', 'hint': 'Sirve para hablar'},
    {'word': 'ROJO', 'emoji': '🔴', 'hint': 'Color del tomate'},
    {'word': 'AZUL', 'emoji': '🔵', 'hint': 'Color del cielo'},
    {'word': 'ROSA', 'emoji': '🌹', 'hint': 'Flor con espinas'},
    {'word': 'NIDO', 'emoji': '🪺', 'hint': 'Casa de los pájaros'},
    {'word': 'CAMA', 'emoji': '🛏️', 'hint': 'Donde dormimos'},
    {'word': 'SOPA', 'emoji': '🍲', 'hint': 'Comida caliente'},
    {'word': 'VACA', 'emoji': '🐄', 'hint': 'Nos da leche'},
    {'word': 'MONO', 'emoji': '🐒', 'hint': 'Animal que trepa'},
    {'word': 'OSO', 'emoji': '🐻', 'hint': 'Grande y peludo'},
    {'word': 'PERA', 'emoji': '🍐', 'hint': 'Fruta verde'},
    {'word': 'MAPA', 'emoji': '🗺️', 'hint': 'Muestra los países'},
    {'word': 'LUPA', 'emoji': '🔍', 'hint': 'Hace ver más grande'},
    {'word': 'NUBE', 'emoji': '☁️', 'hint': 'Está en el cielo'},
    {'word': 'FOCA', 'emoji': '🦭', 'hint': 'Vive en el mar frío'},
    {'word': 'DADO', 'emoji': '🎲', 'hint': 'Tiene seis caras'},
    {'word': 'HOJA', 'emoji': '🍃', 'hint': 'Parte del árbol'},
    {'word': 'TAZA', 'emoji': '☕', 'hint': 'Para beber café'},
    {'word': 'SILLA', 'emoji': '💺', 'hint': 'Nos sentamos'},
    {'word': 'LIBRO', 'emoji': '📖', 'hint': 'Tiene páginas'},
    {'word': 'TIGRE', 'emoji': '🐯', 'hint': 'Felino con rayas'},
    {'word': 'GLOBO', 'emoji': '🎈', 'hint': 'Vuela con aire'},
    {'word': 'FRUTA', 'emoji': '🍎', 'hint': 'Comida sana'},
    {'word': 'ARBOL', 'emoji': '🌳', 'hint': 'Planta grande'},
    {'word': 'ABEJA', 'emoji': '🐝', 'hint': 'Hace miel'},
    {'word': 'BARCO', 'emoji': '🚢', 'hint': 'Navega en el mar'},
    {'word': 'CAMPO', 'emoji': '🌾', 'hint': 'Fuera de la ciudad'},
    {'word': 'CIELO', 'emoji': '🌤️', 'hint': 'Encima de nosotros'},
    {'word': 'ELEFANTE', 'emoji': '🐘', 'hint': 'Animal con trompa'},
    {'word': 'ESCUELA', 'emoji': '🏫', 'hint': 'Donde estudiamos'},
    {'word': 'ESTRELLA', 'emoji': '⭐', 'hint': 'Brilla en el cielo'},
    {'word': 'GALLINA', 'emoji': '🐔', 'hint': 'Pone huevos'},
    {'word': 'HELADO', 'emoji': '🍦', 'hint': 'Postre frío'},
    {'word': 'JIRAFA', 'emoji': '🦒', 'hint': 'Cuello muy largo'},
    {'word': 'MARIPOSA', 'emoji': '🦋', 'hint': 'Insecto con alas bonitas'},
    {'word': 'NARANJA', 'emoji': '🍊', 'hint': 'Fruta cítrica'},
    {'word': 'PAJARO', 'emoji': '🐦', 'hint': 'Animal que vuela'},
    {'word': 'PALOMA', 'emoji': '🕊️', 'hint': 'Ave blanca'},
    {'word': 'CONEJO', 'emoji': '🐰', 'hint': 'Orejas largas'},
    {'word': 'BALLENA', 'emoji': '🐋', 'hint': 'Animal marino enorme'},
    {'word': 'CABALLO', 'emoji': '🐴', 'hint': 'Montamos en él'},
    {'word': 'CASTILLO', 'emoji': '🏰', 'hint': 'Viven los reyes'},
    {'word': 'COCINA', 'emoji': '👩‍🍳', 'hint': 'Donde cocinamos'},
    {'word': 'COMETA', 'emoji': '🪁', 'hint': 'Vuela con el viento'},
    {'word': 'TORTUGA', 'emoji': '🐢', 'hint': 'Lleva caparazón'},
    {'word': 'VENTANA', 'emoji': '🪟', 'hint': 'Miramos por ella'},
    {'word': 'ZAPATO', 'emoji': '👟', 'hint': 'Lo ponemos en el pie'},
    {'word': 'PIRATA', 'emoji': '🏴‍☠️', 'hint': 'Busca tesoros'},
  ];

  static const List<String> _vowels = ['A', 'E', 'I', 'O', 'U'];

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    final shuffled = List<Map<String, String>>.from(_wordBank)
      ..shuffle(random);
    final selected = shuffled.take(totalQuestions).toList();

    return selected.map((item) {
      final word = item['word']!;
      final vowelPositions = <int>[];
      for (int i = 0; i < word.length; i++) {
        if (_vowels.contains(word[i])) {
          vowelPositions.add(i);
        }
      }

      final hiddenIndex = vowelPositions[random.nextInt(vowelPositions.length)];
      final hiddenVowel = word[hiddenIndex];
      final displayWord =
          '${word.substring(0, hiddenIndex)}_${word.substring(
          hiddenIndex + 1)}';

      return {
        'word': word,
        'displayWord': displayWord,
        'hiddenVowel': hiddenVowel,
        'hiddenIndex': hiddenIndex,
        'correctAnswer': hiddenVowel,
        'emoji': item['emoji'],
        'hint': item['hint'],
      };
    }).toList();
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta palabra:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐱', style: TextStyle(fontSize: 40)),
              SizedBox(width: 12),
              Text('Animal que maúlla',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
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
  String getNarrationText(Map<String, dynamic> question) {
    final hint = question['hint'] as String? ?? '';
    return '¿Qué vocal falta? Pista: $hint';
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final displayWord = question['displayWord'] as String;
    final hiddenIndex = question['hiddenIndex'] as int;
    final emoji = question['emoji'] as String? ?? '';
    final hint = question['hint'] as String? ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pista con emoji
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Text(hint,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Palabra con hueco
        Row(
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
        ),
      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            child: Text(
              vowel,
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