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
  Widget buildQuestionWidget(Map<String, dynamic> question) {
    final number = question['number'] as int;
    final askTens = question['askTens'] as bool;
    final digits = number.toString().split('');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          askTens ? '¿Cuántas DECENAS tiene?' : '¿Cuántas UNIDADES tiene?',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dígito de decenas
            _buildDigitCard(
              digits[0],
              'D',
              isHighlighted: askTens,
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            // Dígito de unidades
            _buildDigitCard(
              digits.length > 1 ? digits[1] : '0',
              'U',
              isHighlighted: !askTens,
              color: Colors.blue,
            ),
          ],
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

  Widget _buildDigitCard(String digit, String label, {
    required bool isHighlighted,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isHighlighted ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlighted ? color : Colors.grey.shade300,
              width: isHighlighted ? 4 : 2,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? color : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
}