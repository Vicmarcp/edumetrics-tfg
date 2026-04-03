import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/numeric_keypad.dart';
import 'base_activity_screen.dart';

class SubtractionActivityScreen extends BaseActivityScreen {
  const SubtractionActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'subtraction');

  @override
  State<SubtractionActivityScreen> createState() => _SubtractionActivityState();
}

class _SubtractionActivityState extends BaseActivityState<SubtractionActivityScreen> {
  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    return List.generate(totalQuestions, (index) {
      // Resultado siempre >= 0
      int num1 = random.nextInt(19) + 2; // 2-20
      int num2 = random.nextInt(num1) + 1; // 1 hasta num1

      return {
        'num1': num1,
        'num2': num2,
        'correctAnswer': num1 - num2,
      };
    });
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta resta:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildNumberCard(9, Colors.blue),
          const SizedBox(width: 16),
          const Text('−', style: TextStyle(
              fontSize: 60, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 16),
          _buildNumberCard(3, Colors.red),
          const SizedBox(width: 16),
          const Text('=', style: TextStyle(
              fontSize: 60, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 16),
          _buildNumberCard(6, Colors.teal),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text('9 − 3 = 6 ✓\nResta el segundo número al primero',
              style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  @override
  String getTutorialHint() => 'Resta el segundo número al primero';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    return '${question['num1']} − ${question['num2']}';
  }

  @override
  String getNarrationText(Map<String, dynamic> question) {
    return '¿Cuánto es ${question['num1']} menos ${question['num2']}?';
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNumberCard(question['num1'], Colors.blue),
        const SizedBox(width: 24),
        const Text(
          '−',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 24),
        _buildNumberCard(question['num2'], Colors.red),
        const SizedBox(width: 24),
        const Text(
          '=',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 24),
        _buildNumberCard(null, Colors.teal),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return NumericKeypad(
      maxDigits: 2,
      onSubmit: (value) => handleAnswer(value),
      showDecenas: false,
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

  Widget _buildNumberCard(int? number, Color color) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 4),
      ),
      child: Center(
        child: Text(
          number?.toString() ?? '?',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}