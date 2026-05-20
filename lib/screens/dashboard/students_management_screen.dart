import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/audit_service.dart';
import '../../core/ui_helpers.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
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
        appBar: AppBar(title: const Text('Gestionar Alumnos')),
        body: const ListSkeleton(itemCount: 5),
      );
    }

    if (_noSchool) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestionar Alumnos')),
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
      appBar: AppBar(title: const Text('Gestionar Alumnos')),
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
                    Text('Error al cargar los alumnos',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700])),
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
            return const ListSkeleton(itemCount: 6);
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return EmptyState(
              icon: Icons.school_outlined,
              title: 'Aún no tienes alumnos',
              message: 'Añade el primer alumno para empezar a evaluar',
              actionLabel: 'Añadir alumno',
              onAction: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddStudentScreen()),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;
              final avatarId = data['avatarId'] ?? 1;
              final avatarPath =
                  'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(avatarPath),
                    onBackgroundImageError: (_, _) {},
                    child: data['avatarId'] == null
                        ? Text(
                        (data['name'] ?? '?').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(data['name'] ?? 'Sin nombre'),
                  subtitle: Text('Clase: ${data['className'] ?? 'No asignada'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditStudentScreen(
                                studentId: doc.id,
                                currentName: data['name'] ?? '',
                                currentClass: data['className'] ?? '',
                                currentAvatarId: data['avatarId'] ?? 1,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () {
                          _showDeleteConfirmation(
                              context, doc.id, data['name'] ?? 'este alumno');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Alumno'),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestionar alumno'),
        content: Text('¿Qué deseas hacer con $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('students')
                    .doc(studentId)
                    .update({'isActive': false});
                await AuditService.log(
                  action: 'deactivate_student',
                  targetId: studentId,
                  details: {'name': studentName},
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackbar.success(
                    context,
                    'Alumno dado de baja correctamente',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackbar.error(
                    context,
                    'Error al modificar el alumno. Inténtalo de nuevo.',
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Dar de baja'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPermanentDeleteConfirmation(context, studentId, studentName);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar permanentemente'),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteConfirmation(
      BuildContext context, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminación permanente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar PERMANENTEMENTE a $studentName '
              'y todos sus resultados de actividades?\n\n'
              'Esta acción NO se puede deshacer y se realiza en cumplimiento '
              'del derecho de supresión (RGPD Art. 17).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Eliminar resultados con filtro schoolId
                final results = await FirebaseFirestore.instance
                    .collection('results')
                    .where('schoolId', isEqualTo: _schoolId)
                    .where('studentId', isEqualTo: studentId)
                    .get();

                // Firestore batch limit: 500 operaciones
                const maxBatch = 499;
                var batch = FirebaseFirestore.instance.batch();
                var count = 0;

                for (final doc in results.docs) {
                  if (count >= maxBatch) {
                    await batch.commit();
                    batch = FirebaseFirestore.instance.batch();
                    count = 0;
                  }
                  batch.delete(doc.reference);
                  count++;
                }

                batch.delete(FirebaseFirestore.instance
                    .collection('students')
                    .doc(studentId));

                await batch.commit();
                await AuditService.log(
                  action: 'delete_student',
                  targetId: studentId,
                  details: {'name': studentName},
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackbar.success(
                    context,
                    'Alumno y todos sus datos eliminados permanentemente',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackbar.error(
                    context,
                    'Error al eliminar el alumno. Inténtalo de nuevo.',
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINAR TODO'),
          ),
        ],
      ),
    );
  }
}