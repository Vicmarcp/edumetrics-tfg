import 'package:flutter/material.dart';
import 'dart:math';
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
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  void startQuestion() {
    super.startQuestion();
    _answerController.clear();
  }

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
          style: TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 24),
        Container(
          width: 200,
          child: TextField(
            controller: _answerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 3),
              ),
              hintText: '?',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            enabled: !showFeedback,
            onSubmitted: (_) => _submitAnswer(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: showFeedback ? null : _submitAnswer,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 80),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('COMPROBAR'),
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

  void _submitAnswer() {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un número')),
      );
      return;
    }
    handleAnswer(_answerController.text.trim());
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