import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/ui_helpers.dart';
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

class StudentSelectorScreen extends StatefulWidget {
  const StudentSelectorScreen({super.key});

  @override
  State<StudentSelectorScreen> createState() => _StudentSelectorScreenState();
}

class _StudentSelectorScreenState extends State<StudentSelectorScreen> {
  String? _schoolId;
  bool _loading = true;
  bool _noSchool = false;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() { _noSchool = true; _loading = false; });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final schoolId = userDoc.data()?['schoolId'] as String?;

      if (mounted) {
        if (schoolId == null || schoolId.isEmpty) {
          setState(() { _noSchool = true; _loading = false; });
        } else {
          setState(() { _schoolId = schoolId; _loading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _noSchool = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Selecciona un alumno'), centerTitle: true),
        body: const ListSkeleton(itemCount: 5),
      );
    }

    if (_noSchool) {
      return Scaffold(
        appBar: AppBar(title: const Text('Selecciona un alumno'), centerTitle: true),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('Centro escolar no configurado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Tu cuenta no tiene un centro escolar asignado.\nContacta con el administrador.',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un alumno'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('schoolId', isEqualTo: _schoolId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error al cargar alumnos',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    const Text('Comprueba tu conexión e inténtalo de nuevo.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton(itemCount: 5);
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text('No hay alumnos registrados',
                      style: TextStyle(fontSize: 24, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Añade alumnos desde el modo escritorio',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 24,
              mainAxisSpacing: 24, childAspectRatio: 0.8,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;
              final studentName = data['name'] ?? 'Sin nombre';
              final avatarId = data['avatarId'] ?? 1;
              final avatarPath =
                  'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  onTap: () => _showActivitySelector(context, doc.id, studentName),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(avatarPath, fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                Icon(Icons.person, size: 80, color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(studentName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
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
              _ActivityButton(icon: Icons.compare_arrows, label: 'Comparación Numérica', color: Colors.blue,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ComparisonActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.format_list_numbered, label: 'Secuencia Numérica', color: Colors.green,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SequenceActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.grid_view, label: 'Valor Posicional', color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceValueActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.add_circle_outline, label: 'Sumas Básicas', color: Colors.purple,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => AdditionActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.remove_circle_outline, label: 'Restas Básicas', color: Colors.red,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SubtractionActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.text_fields, label: 'Vocales Perdidas', color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => MissingVowelsActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.music_note, label: 'Contar Sílabas', color: Colors.indigo,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SyllableCountActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.reorder, label: 'Ordenar Frases', color: Colors.teal,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SentenceOrderActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.text_increase, label: 'Mayúsculas', color: Colors.deepPurple,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => CapitalizationActivityScreen(studentId: studentId, studentName: studentName))); }),
              const SizedBox(height: 12),
              _ActivityButton(icon: Icons.extension, label: 'Completar Sílabas', color: Colors.amber,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SyllableCompleteActivityScreen(studentId: studentId, studentName: studentName))); }),
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

  const _ActivityButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.shade50, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
        ]),
      ),
    );
  }
}