import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/accessibility_service.dart';
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

enum _TutorialPhase { example, practice }

abstract class BaseActivityState<T extends BaseActivityScreen>
    extends State<T> {
  int currentQuestion = 0;
  int get totalQuestions => 10;

  late List<Map<String, dynamic>> questions;
  DateTime? questionStartTime;

  bool showFeedback = false;
  bool isCorrect = false;

  int correctCount = 0;
  final List<int> times = [];

  // Cache
  String? _cachedSchoolId;
  String? _cachedTeacherId;
  String? _cachedClassName;

  // Tutorial
  bool _showingTutorial = true;
  _TutorialPhase _tutorialPhase = _TutorialPhase.example;
  late Map<String, dynamic> _tutorialQuestion;
  bool _tutorialAnswered = false;
  bool _tutorialCorrect = false;
  bool _isNarrating = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    questions = generateQuestions();
    final extraQuestions = generateQuestions();
    _tutorialQuestion = extraQuestions.first;
  }

  @override
  void dispose() {
    AccessibilityService.stopSpeaking();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _cachedTeacherId = user?.uid ?? '';

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final schoolId = userDoc.data()?['schoolId'] as String?;
        if (schoolId == null || schoolId.isEmpty) {
          _cachedSchoolId = null;
        } else {
          _cachedSchoolId = schoolId;
        }
      }

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();
      _cachedClassName = studentDoc.data()?['className'] ?? '';
    } catch (_) {}
  }

  // ═══════════════════════════════════════════
  //  MÉTODOS ABSTRACTOS
  // ═══════════════════════════════════════════

  List<Map<String, dynamic>> generateQuestions();
  Widget buildQuestionWidget(Map<String, dynamic> question);
  Widget buildAnswerWidget(Map<String, dynamic> question);
  bool validateAnswer(Map<String, dynamic> question, dynamic userAnswer);
  void onNewQuestion(Map<String, dynamic> question) {}

  Widget buildTutorialExample();
  String getTutorialHint() => '¡Inténtalo tú! Responde como en el ejemplo';

  String describeQuestion(Map<String, dynamic> question) {
    return question['correctAnswer']?.toString() ?? '';
  }

  /// Texto que se narra en voz alta para la pregunta.
  /// Cada actividad puede sobreescribir esto.
  String getNarrationText(Map<String, dynamic> question) {
    return describeQuestion(question);
  }

  // ═══════════════════════════════════════════
  //  LÓGICA DE ACTIVIDAD
  // ═══════════════════════════════════════════

  void startQuestion() {
    questionStartTime = DateTime.now();
    onNewQuestion(questions[currentQuestion]);
    _narrateQuestion();
  }

  Future<void> _narrateQuestion() async {
    if (!AccessibilityService.ttsEnabled.value || _isNarrating) return;
    _isNarrating = true;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && !_showingTutorial && !showFeedback) {
      await AccessibilityService.speak(
          getNarrationText(questions[currentQuestion]));
    }
    _isNarrating = false;
  }

  Future<void> handleAnswer(dynamic userAnswer) async {
    if (showFeedback) return;

    if (_showingTutorial) {
      _handleTutorialAnswer(userAnswer);
      return;
    }

    await AccessibilityService.stopSpeaking();

    final timeSeconds =
        DateTime.now().difference(questionStartTime!).inSeconds;
    final question = questions[currentQuestion];
    final correct = validateAnswer(question, userAnswer);

    if (correct) correctCount++;
    times.add(timeSeconds);

    setState(() {
      showFeedback = true;
      isCorrect = correct;
    });

    if (correct) {
      AccessibilityService.playCorrect();
    } else {
      AccessibilityService.playError();
    }

    await saveResult(question, userAnswer, correct, timeSeconds);

    if (AccessibilityService.ttsEnabled.value) {
      if (correct) {
        await AccessibilityService.speakAndWait('¡Correcto!');
      } else {
        await AccessibilityService.speakAndWait(
            'Incorrecto. La respuesta correcta es ${question['correctAnswer']}');
      }
      await Future.delayed(const Duration(milliseconds: 400));
    } else {
      await Future.delayed(Duration(milliseconds: correct ? 1500 : 3000));
    }

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
        if (AccessibilityService.ttsEnabled.value) {
          await AccessibilityService.speakAndWait(
              'Actividad terminada. Has acertado $correctCount de $totalQuestions');
        }
        showSummary();
      }
    }
  }

  Future<void> _handleTutorialAnswer(dynamic userAnswer) async {
    await AccessibilityService.stopSpeaking();
    final correct = validateAnswer(_tutorialQuestion, userAnswer);
    setState(() {
      _tutorialAnswered = true;
      _tutorialCorrect = correct;
    });

    if (AccessibilityService.ttsEnabled.value) {
      if (correct) {
        await AccessibilityService.speakAndWait(
            '¡Muy bien! Ya sabes cómo hacerlo');
      } else {
        await AccessibilityService.speakAndWait(
            'La respuesta correcta era ${_tutorialQuestion['correctAnswer']}');
      }
    }
  }

  Future<void> _startActivity() async {
    await AccessibilityService.stopSpeaking();
    setState(() {
      _showingTutorial = false;
    });
    startQuestion();
  }

  Future<void> saveResult(
      Map<String, dynamic> question,
      dynamic userAnswer,
      bool correct,
      int timeSeconds,
      ) async {
    if (_cachedSchoolId == null || _cachedSchoolId!.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('results').add({
        'studentId': widget.studentId,
        'className': _cachedClassName ?? '',
        'schoolId': _cachedSchoolId,
        'teacherId': _cachedTeacherId ?? '',
        'activityType': widget.activityType,
        'timeSeconds': timeSeconds,
        'isCorrect': correct,
        'timestamp': FieldValue.serverTimestamp(),
        'questionDetail': describeQuestion(question),
        'correctAnswer': question['correctAnswer']?.toString() ?? '',
        'userAnswer': userAnswer.toString(),
      });
    } catch (_) {}
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

  // ═══════════════════════════════════════════
  //  BOTÓN DE NARRACIÓN
  // ═══════════════════════════════════════════

  Widget _buildSpeakButton(String text) {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityService.ttsEnabled,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextButton.icon(
            onPressed: () => AccessibilityService.speak(text),
            icon: const Icon(Icons.volume_up, size: 24),
            label: const Text('Repetir', style: TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_showingTutorial) {
      return _buildTutorialScreen(context);
    }
    return _buildActivityScreen(context);
  }

  Widget _buildTutorialScreen(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _startActivity,
            child: const Text('Saltar ▶'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _tutorialPhase == _TutorialPhase.example
              ? _buildExamplePhase(context, colorScheme)
              : _buildPracticePhase(context, colorScheme),
        ),
      ),
    );
  }

  Widget _buildExamplePhase(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb, color: colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Text(
                '¡Aprende cómo se hace!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Card(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: buildTutorialExample(),
          ),
        ),
        const SizedBox(height: 40),

        FilledButton.icon(
          onPressed: () async {
            await AccessibilityService.stopSpeaking();
            setState(() {
              _tutorialPhase = _TutorialPhase.practice;
              onNewQuestion(_tutorialQuestion);
            });
            if (AccessibilityService.ttsEnabled.value) {
              await Future.delayed(const Duration(milliseconds: 300));
              AccessibilityService.speak(getNarrationText(_tutorialQuestion));
            }
          },
          icon: const Icon(Icons.arrow_forward, size: 28),
          label: const Text('¡Entendido! Quiero probar',
              style: TextStyle(fontSize: 22)),
          style: FilledButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticePhase(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  getTutorialHint(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!_tutorialAnswered) ...[
          buildQuestionWidget(_tutorialQuestion),
          const SizedBox(height: 32),
          buildAnswerWidget(_tutorialQuestion),
        ],
        if (_tutorialAnswered) ...[
          buildQuestionWidget(_tutorialQuestion),
          const SizedBox(height: 24),
          Icon(
            _tutorialCorrect ? Icons.check_circle : Icons.info_outline,
            size: 100,
            color: _tutorialCorrect
                ? AccessibilityService.correctColor
                : Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            _tutorialCorrect
                ? '¡Muy bien! Ya sabes cómo hacerlo'
                : 'La respuesta correcta era: ${_tutorialQuestion['correctAnswer']}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _tutorialCorrect
                  ? AccessibilityService.correctColor
                  : Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_tutorialCorrect) ...[
            const SizedBox(height: 8),
            const Text(
              '¡No te preocupes! Ahora vamos a practicar',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startActivity,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('¡Empezar actividad!',
                style: TextStyle(fontSize: 22)),
            style: FilledButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: AccessibilityService.correctColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityScreen(BuildContext context) {
    final question = questions[currentQuestion];

    return Scaffold(
      backgroundColor: showFeedback
          ? (isCorrect
          ? AccessibilityService.correctColorLight
          : AccessibilityService.errorColorLight)
          : Theme.of(context).scaffoldBackgroundColor,
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
                // Botón de narración
                _buildSpeakButton(getNarrationText(question)),
                buildQuestionWidget(question),
                const SizedBox(height: 32),
                buildAnswerWidget(question),
                const SizedBox(height: 32),
                if (showFeedback)
                  Column(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 100,
                        color: isCorrect
                            ? AccessibilityService.correctColor
                            : AccessibilityService.errorColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCorrect ? '¡Correcto!' : 'Incorrecto',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? AccessibilityService.correctColor
                              : AccessibilityService.errorColor,
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border:
                            Border.all(color: Colors.orange, width: 2),
                          ),
                          child: Text(
                            'La respuesta correcta es: ${question['correctAnswer']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}