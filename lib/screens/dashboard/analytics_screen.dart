import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'class_analytics_screen.dart';
import 'student_analytics_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _schoolId;
  bool _loading = true;
  bool _noSchool = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Análisis y Estadísticas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_noSchool) {
      return Scaffold(
        appBar: AppBar(title: const Text('Análisis y Estadísticas')),
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
      appBar: AppBar(
        title: const Text('Análisis y Estadísticas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Por Alumno'),
            Tab(icon: Icon(Icons.group), text: 'Por Clase'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StudentListTab(schoolId: _schoolId!),
          ClassAnalyticsScreen(schoolId: _schoolId!),
        ],
      ),
    );
  }
}

class _StudentListTab extends StatelessWidget {
  final String schoolId;
  const _StudentListTab({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
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
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data?.docs ?? [];

        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No hay alumnos registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Añade alumnos desde la sección de gestión',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final data = student.data() as Map<String, dynamic>;
            final avatarId = data['avatarId'] ?? 1;
            final avatarPath =
                'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(avatarPath),
                  onBackgroundImageError: (_, _) {},
                  child: data['avatarId'] == null
                      ? Text(
                      (data['name'] ?? '?').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                title: Text(data['name'] ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['className'] ?? ''),
                trailing: const Icon(Icons.bar_chart, color: Colors.blue),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentAnalyticsScreen(
                        studentId: student.id,
                        studentName: data['name'] ?? 'Sin nombre',
                        schoolId: schoolId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}