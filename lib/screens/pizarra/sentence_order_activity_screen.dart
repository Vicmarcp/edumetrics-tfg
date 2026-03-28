import 'dart:math';

import 'package:flutter/material.dart';

import 'base_activity_screen.dart';

class SentenceOrderActivityScreen extends BaseActivityScreen {
  const SentenceOrderActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'sentence_order');

  @override
  State<SentenceOrderActivityScreen> createState() =>
      _SentenceOrderActivityState();
}

class _SentenceOrderActivityState
    extends BaseActivityState<SentenceOrderActivityScreen> {
  List<String> _selectedWords = [];
  List<String> _availableWords = [];

  // Frases sencillas para 1º-2º primaria
  final List<String> _sentenceBank = [
    'El gato bebe agua',
    'Mi perro es grande',
    'La luna sale hoy',
    'El sol da calor',
    'Yo como pan',
    'La rana salta mucho',
    'Mi casa es roja',
    'El pato nada bien',
    'La vaca come hierba',
    'Yo tengo un gato',
    'El lobo vive solo',
    'La mesa es azul',
    'Mi mama me quiere',
    'El mono sube alto',
    'La flor es bonita',
    'Yo leo un libro',
    'El tren va rapido',
    'La sopa esta rica',
    'Mi papa cocina bien',
    'El oso duerme mucho',
  ];

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    final shuffled = List<String>.from(_sentenceBank)..shuffle(random);
    final selected = shuffled.take(totalQuestions).toList();

    return selected.map((sentence) {
      final words = sentence.split(' ');
      final scrambled = List<String>.from(words)..shuffle(random);
      // Asegurarse de que estén desordenadas
      while (scrambled.join(' ') == words.join(' ')) {
        scrambled.shuffle(random);
      }

      return {
        'sentence': sentence,
        'words': words,
        'scrambled': scrambled,
        'correctAnswer': sentence,
      };
    }).toList();
  }

  @override
  String describeQuestion(Map<String, dynamic> question) {
    return question['sentence'] as String;
  }

  @override
  void onNewQuestion(Map<String, dynamic> question) {
    _selectedWords = [];
    _availableWords = List<String>.from(question['scrambled']);
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ordena las palabras para formar la frase',
          style: TextStyle(fontSize: 26, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        // Zona donde aparecen las palabras seleccionadas
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.teal.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: _selectedWords.isEmpty
              ? const Center(
            child: Text(
              'Pulsa las palabras en orden...',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
              : Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _selectedWords.asMap().entries.map((entry) {
              return Chip(
                label: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.teal,
                deleteIcon: const Icon(Icons.close, color: Colors.white, size: 20),
                onDeleted: () => _removeWord(entry.key),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _availableWords.asMap().entries.map((entry) {
        return ElevatedButton(
          onPressed: () => _selectWord(entry.key),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Text(
            entry.value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _selectWord(int index) {
    setState(() {
      _selectedWords.add(_availableWords[index]);
      _availableWords.removeAt(index);
    });

    // Si ya seleccionó todas las palabras, validar automáticamente
    if (_availableWords.isEmpty) {
      handleAnswer(_selectedWords.join(' '));
    }
  }

  void _removeWord(int index) {
    setState(() {
      _availableWords.add(_selectedWords[index]);
      _selectedWords.removeAt(index);
    });
  }

  @override
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer) {
    return userAnswer.toString() == question['sentence'];
  }
}