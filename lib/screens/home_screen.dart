import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_mode.dart';
import '../screens/pizarra/student_selector_screen.dart';
import 'dashboard/analytics_screen.dart';
import 'dashboard/students_management_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppMode mode;

  const HomeScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(mode == AppMode.pizarra
            ? 'EduMetrics - Pizarra'
            : 'EduMetrics - Panel de Control'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(
                mode == AppMode.pizarra ? Icons.touch_app : Icons.laptop,
                size: 16,
              ),
              label: Text(
                mode == AppMode.pizarra ? 'Modo Pizarra' : 'Modo Desktop',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar modo',
            onPressed: () {
              final newMode = mode == AppMode.pizarra
                  ? AppMode.desktop
                  : AppMode.pizarra;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(mode: newMode),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: mode == AppMode.pizarra
          ? _buildPizarraHome(context, user)
          : _buildDesktopHome(context, user),
    );
  }

  Widget _buildPizarraHome(BuildContext context, User? user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 120, color: Colors.blue),
          const SizedBox(height: 32),
          Text(
            'Bienvenido/a',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 64),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentSelectorScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(300, 120),
              textStyle: const TextStyle(fontSize: 28),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: 48),
                SizedBox(height: 8),
                Text('Iniciar Actividad'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            icon: const Icon(Icons.privacy_tip, size: 20),
            label: const Text('Política de Privacidad'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHome(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido/a, ${user?.email ?? ""}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _MenuCard(
                  icon: Icons.people,
                  title: 'Gestionar Alumnos',
                  description: 'Crear, editar y organizar alumnos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentsManagementScreen(),
                      ),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.bar_chart,
                  title: 'Ver Gráficas',
                  description: 'Análisis y estadísticas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.settings,
                  title: 'Configuración',
                  description: 'Ajustes del sistema',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Próximamente: Configuración')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.privacy_tip, size: 18),
              label: const Text('Política de Privacidad'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}