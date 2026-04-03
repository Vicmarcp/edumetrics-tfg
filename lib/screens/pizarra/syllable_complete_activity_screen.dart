import 'dart:math';

import 'package:flutter/material.dart';

import 'base_activity_screen.dart';

class SyllableCompleteActivityScreen extends BaseActivityScreen {
  const SyllableCompleteActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'syllable_complete');

  @override
  State<SyllableCompleteActivityScreen> createState() =>
      _SyllableCompleteActivityState();
}

class _SyllableCompleteActivityState
    extends BaseActivityState<SyllableCompleteActivityScreen> {
  // Palabras divididas en sílabas con la sílaba que falta y opciones
  final List<Map<String, dynamic>> _wordBank = [
    // Formato: syllables (lista), hiddenIndex (cuál falta), options (3 opciones incluyendo la correcta)
    {'syllables': ['CA', 'SA'], 'hiddenIndex': 0, 'options': ['CA', 'CO', 'CU']},
    {'syllables': ['CA', 'SA'], 'hiddenIndex': 1, 'options': ['SA', 'SO', 'SE']},
    {'syllables': ['ME', 'SA'], 'hiddenIndex': 0, 'options': ['ME', 'MA', 'MO']},
    {'syllables': ['GA', 'TO'], 'hiddenIndex': 1, 'options': ['TO', 'TA', 'TI']},
    {'syllables': ['PE', 'RRO'], 'hiddenIndex': 0, 'options': ['PE', 'PA', 'PO']},
    {'syllables': ['LU', 'NA'], 'hiddenIndex': 1, 'options': ['NA', 'NE', 'NO']},
    {'syllables': ['PA', 'TO'], 'hiddenIndex': 0, 'options': ['PA', 'PO', 'PU']},
    {'syllables': ['RA', 'NA'], 'hiddenIndex': 1, 'options': ['NA', 'NI', 'NU']},
    {'syllables': ['LO', 'BO'], 'hiddenIndex': 0, 'options': ['LO', 'LA', 'LU']},
    {'syllables': ['NU', 'BE'], 'hiddenIndex': 1, 'options': ['BE', 'BA', 'BI']},
    {'syllables': ['DA', 'DO'], 'hiddenIndex': 0, 'options': ['DA', 'DE', 'DI']},
    {'syllables': ['BO', 'CA'], 'hiddenIndex': 1, 'options': ['CA', 'CO', 'CU']},
    {'syllables': ['MA', 'NO'], 'hiddenIndex': 1, 'options': ['NO', 'NA', 'NE']},
    {'syllables': ['DE', 'DO'], 'hiddenIndex': 0, 'options': ['DE', 'DA', 'DU']},
    {'syllables': ['VA', 'CA'], 'hiddenIndex': 0, 'options': ['VA', 'VE', 'VI']},
    {'syllables': ['MO', 'NO'], 'hiddenIndex': 1, 'options': ['NO', 'NA', 'NI']},
    {'syllables': ['PE', 'RA'], 'hiddenIndex': 1, 'options': ['RA', 'RO', 'RE']},
    {'syllables': ['SO', 'PA'], 'hiddenIndex': 0, 'options': ['SO', 'SA', 'SU']},
    {'syllables': ['CA', 'MA'], 'hiddenIndex': 1, 'options': ['MA', 'ME', 'MO']},
    {'syllables': ['FO', 'CA'], 'hiddenIndex': 0, 'options': ['FO', 'FA', 'FU']},
    {'syllables': ['TA', 'ZA'], 'hiddenIndex': 1, 'options': ['ZA', 'ZO', 'ZE']},
    // 3 sílabas
    {'syllables': ['CO', 'NE', 'JO'], 'hiddenIndex': 1, 'options': ['NE', 'NA', 'NO']},
    {'syllables': ['ZA', 'PA', 'TO'], 'hiddenIndex': 0, 'options': ['ZA', 'ZO', 'ZU']},
    {'syllables': ['CO', 'CI', 'NA'], 'hiddenIndex': 2, 'options': ['NA', 'NE', 'NI']},
    {'syllables': ['HE', 'LA', 'DO'], 'hiddenIndex': 1, 'options': ['LA', 'LO', 'LE']},
    {'syllables': ['PA', 'LO', 'MA'], 'hiddenIndex': 2, 'options': ['MA', 'MO', 'ME']},
    {'syllables': ['TOR', 'TU', 'GA'], 'hiddenIndex': 1, 'options': ['TU', 'TA', 'TO']},
    {'syllables': ['PI', 'RA', 'TA'], 'hiddenIndex': 0, 'options': ['PI', 'PA', 'PU']},
    {'syllables': ['CO', 'ME', 'TA'], 'hiddenIndex': 2, 'options': ['TA', 'TO', 'TE']},
    {'syllables': ['GA', 'LLI', 'NA'], 'hiddenIndex': 1, 'options': ['LLI', 'LLA', 'LLO']},
  ];

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_wordBank)
      ..shuffle(random);

    return shuffled.take(totalQuestions).map((item) {
      // Barajar las opciones
      final options = List<String>.from(item['options'])..shuffle(random);
      return {
        'syllables': item['syllables'],
        'hiddenIndex': item['hiddenIndex'],
        'options': options,
        'correctAnswer': (item['syllables'] as List)[item['hiddenIndex']],
      };
    }).toList();
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta palabra incompleta:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _exampleSyllable('GA', false),
          _exampleSyllable('?', true),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text('La palabra es GA-TO\nFalta la sílaba TO ✓',
              style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _exampleSyllable(String text, bool isHidden) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isHidden ? Colors.amber.withValues(alpha: 0.15) : Colors.green
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isHidden ? Colors.amber.shade700 : Colors.green,
              width: isHidden ? 4 : 2),
        ),
        child: Center(child: Text(text, style: TextStyle(fontSize: 44,
            fontWeight: FontWeight.bold,
            color: isHidden ? Colors.amber.shade700 : Colors.green.shade700))),
      ),
    );
  }

  @override
  String getTutorialHint() =>
      'Elige la sílaba que falta para completar la palabra';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    final syllables = question['syllables'] as List;
    final hiddenIndex = question['hiddenIndex'] as int;
    final parts = syllables
        .asMap()
        .entries
        .map((e) => e.key == hiddenIndex ? '?' : e.value.toString())
        .toList();
    return '${parts.join('-')} (${syllables.join('-')})';
  }

  @override
  String getNarrationText(Map<String, dynamic> question) {
    final syllables = question['syllables'] as List;
    final hiddenIndex = question['hiddenIndex'] as int;
    final visible = syllables
        .asMap()
        .entries
        .where((e) => e.key != hiddenIndex)
        .map((e) => e.value)
        .join(', ');
    return '¿Qué sílaba falta? Las sílabas visibles son: $visible';
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final syllables = question['syllables'] as List;
    final hiddenIndex = question['hiddenIndex'] as int;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¿Qué sílaba falta?',
          style: TextStyle(fontSize: 26, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: syllables.asMap().entries.map<Widget>((entry) {
            final isHidden = entry.key == hiddenIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                constraints: const BoxConstraints(minWidth: 90),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isHidden
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHidden ? Colors.amber.shade700 : Colors.green,
                    width: isHidden ? 4 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isHidden ? '?' : entry.value.toString(),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: isHidden ? Colors.amber.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    final options = question['options'] as List;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map<Widget>((option) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () => handleAnswer(option),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            child: Text(
              option.toString(),
              style: const TextStyle(
                fontSize: 40,
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
    return userAnswer.toString() == question['correctAnswer'];
  }
}