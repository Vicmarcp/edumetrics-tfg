import 'package:flutter/material.dart';

class ActivitySummaryScreen extends StatelessWidget {
  final String studentName;
  final int correctAnswers;
  final int totalQuestions;
  final List<int> timesInSeconds;

  const ActivitySummaryScreen({
    super.key,
    required this.studentName,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timesInSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final averageTime = timesInSeconds.isEmpty
        ? 0
        : (timesInSeconds.reduce((a, b) => a + b) / timesInSeconds.length).round();

    final percentage = (correctAnswers / totalQuestions * 100).round();

    // Emoji según rendimiento
    String emoji;
    String message;
    MaterialColor color;

    if (percentage >= 90) {
      emoji = '🌟';
      message = '¡Excelente trabajo!';
      color = Colors.green;
    } else if (percentage >= 70) {
      emoji = '😊';
      message = '¡Muy bien!';
      color = Colors.blue;
    } else if (percentage >= 50) {
      emoji = '👍';
      message = '¡Buen intento!';
      color = Colors.orange;
    } else {
      emoji = '💪';
      message = '¡Sigue practicando!';
      color = Colors.red;
    }

    return Scaffold(
      backgroundColor: color.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                emoji,
                style: const TextStyle(fontSize: 120),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Tarjetas de estadísticas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    icon: Icons.check_circle,
                    label: 'Aciertos',
                    value: '$correctAnswers/$totalQuestions',
                    color: Colors.green,
                  ),
                  _StatCard(
                    icon: Icons.timer,
                    label: 'Tiempo promedio',
                    value: '${averageTime}s',
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: Icons.percent,
                    label: 'Porcentaje',
                    value: '$percentage%',
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 64),

              // Botón grande para volver
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(300, 80),
                  textStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Volver al Inicio'),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}