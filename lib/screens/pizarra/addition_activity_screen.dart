import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/numeric_keypad.dart';
import 'base_activity_screen.dart';

class AdditionActivityScreen extends BaseActivityScreen {
  const AdditionActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'addition');

  @override
  State<AdditionActivityScreen> createState() => _AdditionActivityState();
}

class _AdditionActivityState extends BaseActivityState<AdditionActivityScreen> {
  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    return List.generate(totalQuestions, (index) {
      // Sumas cuyo resultado no supere 20
      int num1 = random.nextInt(10) + 1; // 1-10
      int maxNum2 = 20 - num1;
      int num2 = random.nextInt(maxNum2) + 1;

      return {
        'num1': num1,
        'num2': num2,
        'correctAnswer': num1 + num2,
      };
    });
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira esta suma:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildNumberCard(3, Colors.blue),
          const SizedBox(width: 16),
          const Text('+', style: TextStyle(
              fontSize: 60, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 16),
          _buildNumberCard(4, Colors.green),
          const SizedBox(width: 16),
          const Text('=', style: TextStyle(
              fontSize: 60, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 16),
          _buildNumberCard(7, Colors.purple),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text('3 + 4 = 7 ✓\nSuma los dos números',
              style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  @override
  String getTutorialHint() => 'Suma los dos números y escribe el resultado';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    return '${question['num1']} + ${question['num2']}';
  }

  @override
  String getNarrationText(Map<String, dynamic> question) {
    return '¿Cuánto es ${question['num1']} más ${question['num2']}?';
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNumberCard(question['num1'], Colors.blue),
        const SizedBox(width: 24),
        const Text(
          '+',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 24),
        _buildNumberCard(question['num2'], Colors.green),
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
        _buildNumberCard(null, Colors.purple),
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