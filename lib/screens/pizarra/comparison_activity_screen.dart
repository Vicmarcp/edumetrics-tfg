import 'dart:math';

import 'package:flutter/material.dart';

import 'base_activity_screen.dart';

class ComparisonActivityScreen extends BaseActivityScreen {
  const ComparisonActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'comparison');

  @override
  State<ComparisonActivityScreen> createState() => _ComparisonActivityState();
}

class _ComparisonActivityState extends BaseActivityState<ComparisonActivityScreen> {
  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    return List.generate(totalQuestions, (index) {
      int num1 = random.nextInt(20) + 1;
      int num2 = random.nextInt(20) + 1;

      while (num1 == num2) {
        num2 = random.nextInt(20) + 1;
      }

      return {
        'num1': num1,
        'num2': num2,
        'correctAnswer': num1 > num2 ? 'mayor' : 'menor',
      };
    });
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira estos dos números:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildNumberCard(15),
          const SizedBox(width: 24),
          const Text('vs',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          _buildNumberCard(8),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: const Text(
            '15 es MAYOR que 8\nporque 15 es más grande ✓',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  String getTutorialHint() =>
      '¿El primer número es mayor o menor que el segundo?';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    return '${question['num1']} vs ${question['num2']}';
  }

  @override
  String getNarrationText(Map<String, dynamic> question) {
    return '¿${question['num1']} es mayor o menor que ${question['num2']}?';
  }
  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNumberCard(question['num1']),
        const SizedBox(width: 40),
        const Text(
          'vs',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 40),
        _buildNumberCard(question['num2']),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¿El primer número es...?',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnswerButton('MAYOR', 'mayor'),
            const SizedBox(width: 40),
            _buildAnswerButton('MENOR', 'menor'),
          ],
        ),
      ],
    );
  }

  @override
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer) {
    return userAnswer == question['correctAnswer'];
  }

  // Widgets auxiliares específicos de esta actividad
  Widget _buildNumberCard(int number) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue, width: 4),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String label, String value) {
    return ElevatedButton(
      onPressed: showFeedback ? null : () => handleAnswer(value),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 150),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}