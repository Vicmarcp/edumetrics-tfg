import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'addition_activity_screen.dart';
import 'capitalization_activity_screen.dart';
import 'comparison_activity_screen.dart';
import 'missing_vowels_activity_screen.dart';
import 'place_value_activity_screen.dart';
import 'sentence_order_activity_screen.dart';
import 'sequence_activity_screen.dart';
import 'subtraction_activity_screen.dart';
import 'syllable_complete_activity_screen.dart';
import 'syllable_count_activity_screen.dart';

class StudentSelectorScreen extends StatelessWidget {
  const StudentSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un alumno'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No hay alumnos registrados',
                    style: TextStyle(fontSize: 24, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Grid de alumnos con avatares grandes
          return GridView.builder(
            padding: const EdgeInsets.all(32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;
              final studentName = data['name'] ?? 'Sin nombre';
              final avatarId = data['avatarId'] ?? 1;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () {
                    // Mostrar diálogo para elegir actividad
                    _showActivitySelector(context, doc.id, studentName);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar grande
                        Expanded(
                          child: Image.asset(
                            'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Nombre del alumno
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  void _showActivitySelector(BuildContext context, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona una actividad'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActivityButton(
              icon: Icons.compare_arrows,
              label: 'Comparación Numérica',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComparisonActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.format_list_numbered,
              label: 'Secuencia Numérica',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SequenceActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.grid_view,
              label: 'Valor Posicional',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceValueActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.add_circle_outline,
              label: 'Sumas Básicas',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdditionActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.remove_circle_outline,
              label: 'Restas Básicas',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubtractionActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.text_fields,
              label: 'Vocales Perdidas',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MissingVowelsActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.music_note,
              label: 'Contar Sílabas',
              color: Colors.indigo,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SyllableCountActivityScreen(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.reorder,
              label: 'Ordenar Frases',
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SentenceOrderActivityScreen(
                          studentId: studentId,
                          studentName: studentName,
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.text_increase,
              label: 'Mayúsculas',
              color: Colors.deepPurple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CapitalizationActivityScreen(
                          studentId: studentId,
                          studentName: studentName,
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityButton(
              icon: Icons.extension,
              label: 'Completar Sílabas',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SyllableCompleteActivityScreen(
                          studentId: studentId,
                          studentName: studentName,
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
class _ActivityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  const _ActivityButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}