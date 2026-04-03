import 'dart:math';

import 'package:flutter/material.dart';

import '../../widgets/numeric_keypad.dart';
import 'base_activity_screen.dart';

class PlaceValueActivityScreen extends BaseActivityScreen {
  const PlaceValueActivityScreen({
    super.key,
    required super.studentId,
    required super.studentName,
  }) : super(activityType: 'place_value');

  @override
  State<PlaceValueActivityScreen> createState() => _PlaceValueActivityState();
}

class _PlaceValueActivityState extends BaseActivityState<PlaceValueActivityScreen> {
  @override
  List<Map<String, dynamic>> generateQuestions() {
    final random = Random();
    return List.generate(totalQuestions, (index) {
      // Números del 10 al 20 (tienen decenas y unidades)
      int number = random.nextInt(11) + 10; // 10-20

      // Alternar entre preguntar decenas y unidades
      bool askTens = index % 2 == 0;

      return {
        'number': number,
        'askTens': askTens,
        'correctAnswer': askTens ? (number ~/ 10) : (number % 10),
      };
    });
  }

  @override
  Widget buildTutorialExample() {
    return Column(
      children: [
        const Text('Mira este número:',
            style: TextStyle(fontSize: 22, color: Colors.grey)),
        const SizedBox(height: 16),
        Container(
          width: 160, height: 160,
          decoration: BoxDecoration(color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple, width: 4)),
          child: const Center(child: Text('14', style: TextStyle(fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.purple))),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text('1 DECENA (el 1 vale 10)', style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700)),
            const SizedBox(height: 8),
            const Text('4 UNIDADES', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            const Text('14 = 1 decena + 4 unidades ✓', style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold)),
          ]),
        ),
      ],
    );
  }

  @override
  String getTutorialHint() => 'Cuenta las decenas o las unidades del número';
  @override
  String describeQuestion(Map<String, dynamic> question) {
    final askTens = question['askTens'] as bool;
    return '${question['number']}: ¿${askTens ? 'Decenas' : 'Unidades'}?';
  }

  @override
  String getNarrationText(Map<String, dynamic> question) {
    final askTens = question['askTens'] as bool;
    return '¿Cuántas ${askTens
        ? 'decenas'
        : 'unidades'} tiene el número ${question['number']}?';
  }

  @override
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final number = question['number'] as int;
    final askTens = question['askTens'] as bool;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mostrar el número completo, sin pistas
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple, width: 4),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          askTens ? '¿Cuántas DECENAS tiene?' : '¿Cuántas UNIDADES tiene?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: askTens ? Colors.orange : Colors.blue,
          ),
        ),
      ],
    );
  }

  @override
  Widget buildAnswerWidget(Map<String, dynamic> question) {
    return NumericKeypad(
      maxDigits: 1,
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
}