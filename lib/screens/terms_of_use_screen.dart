import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos de Uso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title('1. Aceptación'),
            _P(
              'El uso de EduMetrics implica la aceptación expresa de los '
              'presentes Términos de Uso y de la Política de Privacidad. '
              'Si no está de acuerdo, no debe usar la aplicación.',
            ),

            _Title('2. Descripción del servicio'),
            _P(
              'EduMetrics es una herramienta educativa de apoyo a la '
              'evaluación. Permite a profesores autorizados:',
            ),
            _P(
              '• Gestionar fichas anónimas de alumnos (nombre, clase, avatar)',
            ),
            _P('• Realizar 10 tipos de actividades interactivas'),
            _P('• Consultar estadísticas individuales y por clase'),
            _P('• Exportar resultados a Excel y PDF'),

            _Title('3. Obligaciones del usuario'),
            _P('El profesor que usa la aplicación se compromete a:'),
            _P('• Proteger sus credenciales de acceso y no compartirlas'),
            _P(
              '• Recabar el consentimiento parental antes de registrar a '
              'cualquier menor (Art. 7 LOPDGDD)',
            ),
            _P(
              '• No introducir datos identificativos sensibles más allá del '
              'nombre del alumno y su clase',
            ),
            _P(
              '• No utilizar la aplicación con fines distintos a la evaluación '
              'pedagógica para la que está diseñada',
            ),
            _P(
              '• Cerrar sesión al finalizar el uso, especialmente en '
              'dispositivos compartidos',
            ),

            _Title('4. Limitaciones de uso'),
            _P('Está prohibido:'),
            _P(
              '• Realizar ingeniería inversa del código o intentar acceder a '
              'datos de otros centros',
            ),
            _P('• Usar la aplicación para fines comerciales sin autorización'),
            _P(
              '• Subir fotografías reales de menores como avatares (la app '
              'proporciona avatares genéricos)',
            ),
            _P('• Compartir datos de los alumnos con terceros no autorizados'),

            _Title('5. Suspensión del acceso'),
            _P(
              'El administrador puede suspender o cancelar el acceso de un '
              'usuario en caso de incumplimiento de estos términos, mal uso '
              'demostrable o solicitud del centro educativo.',
            ),

            _Title('6. Disponibilidad'),
            _P(
              'La aplicación se ofrece como herramienta académica sin '
              'garantías de disponibilidad continua. Pueden producirse '
              'periodos de mantenimiento o interrupciones por causas '
              'técnicas ajenas al titular (caída de Firebase, etc.).',
            ),

            _Title('7. Modificaciones'),
            _P(
              'El titular puede modificar estos términos. El uso continuado '
              'de la aplicación tras la publicación de los cambios implica '
              'su aceptación.',
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Última actualización: marzo 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _P extends StatelessWidget {
  final String text;

  const _P(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
    );
  }
}
