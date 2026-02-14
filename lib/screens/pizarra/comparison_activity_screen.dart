import 'package:flutter/material.dart';
import 'dart:math';
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