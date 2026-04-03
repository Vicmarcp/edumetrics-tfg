import 'package:flutter/material.dart';

import '../core/demo_seed_service.dart';
import '../core/ui_helpers.dart';

class DemoDataScreen extends StatefulWidget {
  const DemoDataScreen({super.key});

  @override
  State<DemoDataScreen> createState() => _DemoDataScreenState();
}

class _DemoDataScreenState extends State<DemoDataScreen> {
  bool _busy = false;
  String? _result;

  Future<void> _seed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generar datos de demo'),
        content: const Text(
          'Se crearán 5 alumnos ficticios y unos 200 resultados '
          'distribuidos en los últimos 90 días.\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await DemoSeedService.seedDemoData();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
    if (result.startsWith('OK')) {
      AppSnackbar.success(context, 'Datos de demo creados correctamente');
    } else {
      AppSnackbar.error(context, result);
    }
  }

  Future<void> _clear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar datos de demo'),
        content: const Text(
          'Se eliminarán todos los alumnos y resultados marcados como demo. '
          'Los datos reales NO se verán afectados.\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await DemoSeedService.clearDemoData();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
    if (result.startsWith('OK')) {
      AppSnackbar.success(context, 'Datos de demo eliminados');
    } else {
      AppSnackbar.error(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos de demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta pantalla genera datos ficticios para probar la '
                        'aplicación o para demostraciones. Los datos llevan '
                        'una marca interna (isDemo) y se pueden eliminar en '
                        'bloque cuando se desee.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _busy ? null : _seed,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar 5 alumnos + 200 resultados'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _busy ? null : _clear,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Eliminar todos los datos de demo',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            if (_busy)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Procesando...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.startsWith('OK')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    color: _result!.startsWith('OK')
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
