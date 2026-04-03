import 'dart:math';

import 'package:flutter/material.dart';

import 'base_activity_screen.dart';

class CapitalizationActivityScreen extends BaseActivityScreen {
  const CapitalizationActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'capitalization');

  @override
  State<CapitalizationActivityScreen> createState() =>
      _CapitalizationActivityState();
}

class _CapitalizationActivityState
    extends BaseActivityState<CapitalizationActivityScreen> {
  // Frases donde una palabra necesita mayúscula (se muestra toda en minúsculas)
  // El niño debe tocar la palabra que necesita mayúscula
  final List<Map<String, dynamic>> _sentenceBank = [
    // Inicio de frase
    {
      'sentence': 'el gato duerme',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'El'
    },
    {
      'sentence': 'la casa es grande',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'La'
    },
    {
      'sentence': 'mi perro corre',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'Mi'
    },
    {
      'sentence': 'un pato nada',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'Un'
    },
    {
      'sentence': 'la luna brilla',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'La'
    },
    {
      'sentence': 'el sol calienta',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'El'
    },
    {
      'sentence': 'una flor bonita',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'Una'
    },
    {
      'sentence': 'los pajaros cantan',
      'correctIndex': 0,
      'rule': 'inicio',
      'capitalized': 'Los'
    },
    // Nombres propios
    {
      'sentence': 'yo soy maria',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'María'
    },
    {
      'sentence': 'mi amigo pedro',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Pedro'
    },
    {
      'sentence': 'ella es lucia',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Lucía'
    },
    {
      'sentence': 'el perro toby',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Toby'
    },
    {
      'sentence': 'vivo en madrid',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Madrid'
    },
    {
      'sentence': 'vamos a sevilla',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Sevilla'
    },
    {
      'sentence': 'mi gato luna',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Luna'
    },
    {
      'sentence': 'el rio tajo',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Tajo'
    },
    {
      'sentence': 'mi amiga sofia',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Sofía'
    },
    {
      'sentence': 'vivo en valencia',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Valencia'
    },
    {
      'sentence': 'mi primo carlos',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Carlos'
    },
    {
      'sentence': 'ella es ana',
      'correctIndex': 2,
      'rule': 'nombre',
      'capitalized': 'Ana'
    },
  ];

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_sentenceBank)
      ..shuffle(random);
    return shuffled.take(totalQuestions).map((item) {
      return {
        'sentence': item['sentence'],
        'correctIndex': item['correctIndex'],
        'rule': item['rule'],
        // correctAnswer es la palabra ya capitalizada para mostrar en feedback
        'correctAnswer': item['capitalized'],
      };
    }).toList();
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta frase:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, children: ['yo', 'soy', 'maria'].map((w) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple, width: 2)),
              child: Text(w, style: const TextStyle(fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
            )).toList()),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text(
              '"maria" necesita MAYÚSCULA\nporque es un nombre propio ✓\nSe escribe: María',
              style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  @override
  String getTutorialHint() => 'Pulsa la palabra que debe ir con mayúscula';
  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final rule = question['rule'] as String;
    final hint = rule == 'inicio'
        ? '¿Qué palabra va con mayúscula al empezar la frase?'
        : '¿Qué palabra es un nombre propio?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hint,
          style: const TextStyle(fontSize: 26, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Icon(Icons.arrow_downward, size: 32, color: Colors.grey),
      ],
    );
  }

  @override
  String describeQuestion(Map<String, dynamic> question) {
    final rule = question['rule'] as String;
    return '${question['sentence']} (${rule == 'inicio'
        ? 'inicio de frase'
        : 'nombre propio'})';
  }

  @override
  String getNarrationText(Map<String, dynamic> question) {
    final rule = question['rule'] as String;
    return rule == 'inicio'
        ? '¿Qué palabra va con mayúscula al empezar la frase?'
        : '¿Qué palabra es un nombre propio?';
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    final sentence = question['sentence'] as String;
    final words = sentence.split(' ');

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: words.asMap().entries.map((entry) {
        return ElevatedButton(
          onPressed: () => handleAnswer(entry.value),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade50,
            foregroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            elevation: 3,
          ),
          child: Text(
            entry.value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer) {
    final sentence = question['sentence'] as String;
    final words = sentence.split(' ');
    final lowercaseCorrect = words[question['correctIndex'] as int];
    return userAnswer.toString() == lowercaseCorrect;
  }
}