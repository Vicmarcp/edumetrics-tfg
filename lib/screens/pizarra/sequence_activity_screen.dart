import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/numeric_keypad.dart';
import 'base_activity_screen.dart';

class SequenceActivityScreen extends BaseActivityScreen {
  const SequenceActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'sequence');

  @override
  State<SequenceActivityScreen> createState() => _SequenceActivityState();
}

class _SequenceActivityState extends BaseActivityState<SequenceActivityScreen> {

  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    return List.generate(totalQuestions, (index) {
      // Generar secuencia de 3 números consecutivos
      int middle = random.nextInt(18) + 2; // Entre 2 y 19

      return {
        'num1': middle - 1,
        'num2': middle,
        'num3': middle + 1,
        'correctAnswer': middle,
      };
    });
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta serie de números:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildNumberCard('4'),
          const SizedBox(width: 16),
          _buildNumberCard('?', isQuestion: true),
          const SizedBox(width: 16),
          _buildNumberCard('6'),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text(
            'El número que falta es 5\nporque va entre 4 y 6: 4, 5, 6 ✓',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  String getTutorialHint() => 'Escribe el número que va en medio';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    return '${question['num1']}, ?, ${question['num3']}';
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¿Qué número falta?',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberCard(question['num1'].toString()),
            const SizedBox(width: 20),
            _buildNumberCard('?', isQuestion: true),
            const SizedBox(width: 20),
            _buildNumberCard(question['num3'].toString()),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Escribe el número que falta:',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        NumericKeypad(
          maxDigits: 2, // Secuencia puede tener números hasta 20 (2 dígitos)
          onSubmit: (value) => handleAnswer(value),
          showDecenas: false, // Por ahora sin color naranja
        ),
      ],
    );
  }

  @override
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer) {
    try {
      final num = int.parse(userAnswer.toString());
      return num == question['correctAnswer'];
    } catch (e) {
      return false;
    }
  }

  Widget _buildNumberCard(String text, {bool isQuestion = false}) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isQuestion ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isQuestion ? Colors.orange : Colors.blue,
          width: 4,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: isQuestion ? Colors.orange : Colors.blue,
          ),
        ),
      ),
    );
  }
}