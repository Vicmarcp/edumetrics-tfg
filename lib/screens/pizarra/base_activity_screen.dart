import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'activity_summary_screen.dart';

abstract class BaseActivityScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String activityType;

  const BaseActivityScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.activityType,
  });
}

abstract class BaseActivityState<T extends BaseActivityScreen> extends State<T> {
  int currentQuestion = 0;
  int get totalQuestions => 10; // Puede sobrescribirse

  late List<Map<String, dynamic>> questions;
  DateTime? questionStartTime;

  bool showFeedback = false;
  bool isCorrect = false;

  int correctCount = 0;
  final List<int> times = [];

  @override
  void initState() {
    super.initState();
    questions = generateQuestions();
    startQuestion();
  }

  // MÉTODOS ABSTRACTOS - Cada actividad DEBE implementarlos
  List<Map<String, dynamic>> generateQuestions();
  Widget buildQuestionWidget(Map<String, dynamic> question);
  Widget buildAnswerWidget(Map<String, dynamic> question);
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer);

  // MÉTODOS CON IMPLEMENTACIÓN - Compartidos por todas las actividades
  void startQuestion() {
    questionStartTime = DateTime.now();
  }

  Future<void> handleAnswer(dynamic userAnswer) async {
    if (showFeedback) return;

    final timeSeconds = DateTime.now().difference(questionStartTime!).inSeconds;
    final question = questions[currentQuestion];
    final correct = validateAnswer(question, userAnswer);

    if (correct) correctCount++;
    times.add(timeSeconds);

    setState(() {
      showFeedback = true;
      isCorrect = correct;
    });

    await saveResult(question, userAnswer, correct, timeSeconds);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        showFeedback = false;
      });

      if (currentQuestion + 1 < totalQuestions) {
        setState(() {
          currentQuestion++;
        });
        startQuestion();
      } else {
        showSummary();
      }
    }
  }

  Future<void> saveResult(
      Map<String, dynamic> question,
      dynamic userAnswer,
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
        'className': '',
        'schoolId': schoolId,
        'teacherId': user?.uid ?? '',
        'activityType': widget.activityType,
        'variant': 1,
        'timeSeconds': timeSeconds,
        'isCorrect': correct,
        'timestamp': FieldValue.serverTimestamp(),
        'activityData': {
          'question': question.toString(),
          'correctAnswer': question['correctAnswer'],
          'userAnswer': userAnswer.toString(),
          ...question, // Incluye todos los datos de la pregunta
        },
      });
    } catch (e) {
      debugPrint('Error saving result: $e');
    }
  }

  void showSummary() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActivitySummaryScreen(
          studentName: widget.studentName,
          correctAnswers: correctCount,
          totalQuestions: totalQuestions,
          timesInSeconds: times,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];

    return Scaffold(
      backgroundColor: showFeedback
          ? (isCorrect ? Colors.green.shade100 : Colors.red.shade100)
          : Colors.white,
      appBar: AppBar(
        title: Text(widget.studentName),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${currentQuestion + 1}/$totalQuestions',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildQuestionWidget(question),
                const SizedBox(height: 32),
                buildAnswerWidget(question),
                const SizedBox(height: 32),
                if (showFeedback)
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 120,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}