import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_mode.dart';
import 'dashboard/students_management_screen.dart';

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
          // Indicador de modo
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
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

  // Vista para modo Pizarra
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
          // Botones grandes para pizarra
          ElevatedButton(
            onPressed: () {
              // TODO: Navegar a selector de alumno
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente: Selector de alumno')),
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
        ],
      ),
    );
  }

  // Vista para modo Desktop
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
                    Navigator.of(context).push(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente: Gráficas')),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.settings,
                  title: 'Configuración',
                  description: 'Ajustes del sistema',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente: Configuración')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget reutilizable para las tarjetas del menú
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