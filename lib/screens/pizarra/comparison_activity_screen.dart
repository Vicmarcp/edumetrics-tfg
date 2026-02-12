import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'activity_summary_screen.dart';

class ComparisonActivityScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ComparisonActivityScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ComparisonActivityScreen> createState() => _ComparisonActivityScreenState();
}

class _ComparisonActivityScreenState extends State<ComparisonActivityScreen> {
  int _currentQuestion = 0;
  final int _totalQuestions = 10;

  late List<Map<String, dynamic>> _questions;
  DateTime? _questionStartTime;

  bool _showFeedback = false;
  bool _isCorrect = false;

  int _correctCount = 0;
  final List<int> _times = [];

  @override
  void initState() {
    super.initState();
    _generateQuestions();
    _startQuestion();
  }

  void _generateQuestions() {
    final random = Random();
    _questions = List.generate(_totalQuestions, (index) {
      // Generar dos números diferentes entre 1 y 20
      int num1 = random.nextInt(20) + 1;
      int num2 = random.nextInt(20) + 1;

      // Asegurar que sean diferentes
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

  void _startQuestion() {
    _questionStartTime = DateTime.now();
  }

  Future<void> _handleAnswer(String answer) async {
    if (_showFeedback) return; // Prevenir múltiples clics

    final timeSeconds = DateTime.now().difference(_questionStartTime!).inSeconds;
    final question = _questions[_currentQuestion];
    final correct = answer == question['correctAnswer'];

    if (correct) _correctCount++;
    _times.add(timeSeconds);

    setState(() {
      _showFeedback = true;
      _isCorrect = correct;
    });

    // Guardar resultado en Firestore
    await _saveResult(question, answer, correct, timeSeconds);

    // Esperar 1.5 segundos mostrando feedback
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _showFeedback = false;
      });

      // Siguiente pregunta o finalizar
      if (_currentQuestion + 1 < _totalQuestions) {
        setState(() {
          _currentQuestion++;
        });
        _startQuestion();
      } else {
        _showSummary();
      }
    }
  }

  Future<void> _saveResult(
      Map<String, dynamic> question,
      String userAnswer,
      bool correct,
      int timeSeconds,
      ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      final schoolId = userDoc.data()?['schoolId'] ?? 'default-school';

      await FirebaseFirestore.instance.collection('results').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'className': '', // Podemos obtenerlo del documento del estudiante si lo necesitas
        'schoolId': schoolId,
        'teacherId': user?.uid ?? '',
        'activityType': 'comparison',
        'variant': 1, // Por ahora variante 1
        'timeSeconds': timeSeconds,
        'isCorrect': correct,
        'timestamp': FieldValue.serverTimestamp(),
        'activityData': {
          'question': '${question['num1']} vs ${question['num2']}',
          'correctAnswer': question['correctAnswer'],
          'userAnswer': userAnswer,
          'num1': question['num1'],
          'num2': question['num2'],
        },
      });
    } catch (e) {
      debugPrint('Error saving result: $e');
    }
  }

  void _showSummary() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActivitySummaryScreen(
          studentName: widget.studentName,
          correctAnswers: _correctCount,
          totalQuestions: _totalQuestions,
          timesInSeconds: _times,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];

    return Scaffold(
      backgroundColor: _showFeedback
          ? (_isCorrect ? Colors.green.shade100 : Colors.red.shade100)
          : Colors.white,
      appBar: AppBar(
        title: Text(widget.studentName),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentQuestion + 1}/$_totalQuestions',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Números a comparar
            Row(
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
            ),

            // Pregunta
            const Text(
              '¿El primer número es...?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
            ),

            // Botones de respuesta
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnswerButton('MAYOR', 'mayor'),
                const SizedBox(width: 40),
                _buildAnswerButton('MENOR', 'menor'),
              ],
            ),

            // Feedback
            if (_showFeedback)
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                size: 120,
                color: _isCorrect ? Colors.green : Colors.red,
              ),
          ],
        ),
      ),
    );
  }

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
      onPressed: _showFeedback ? null : () => _handleAnswer(value),
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