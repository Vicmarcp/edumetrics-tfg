import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad de EduMetrics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: marzo 2026',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSection(
              titleColor,
              '1. Responsable del tratamiento',
              'EduMetrics es una aplicación educativa desarrollada como Proyecto de Fin de Ciclo. '
                  'El responsable del tratamiento de los datos es el centro educativo que utiliza la aplicación, '
                  'de acuerdo con el Reglamento General de Protección de Datos (RGPD) y la Ley Orgánica 3/2018 '
                  'de Protección de Datos Personales y garantía de los derechos digitales (LOPDGDD).',
            ),
            _buildSection(
              titleColor,
              '2. Datos que recopilamos',
              'La aplicación recopila únicamente los siguientes datos de los alumnos:\n\n'
                  '• Nombre (para identificación en el aula)\n'
                  '• Clase/grupo al que pertenece\n'
                  '• Avatar seleccionado (imagen genérica, no fotografía real)\n'
                  '• Resultados de las actividades educativas (aciertos, errores y tiempos)\n\n'
                  'De los profesores se recopila:\n\n'
                  '• Correo electrónico (para autenticación)\n'
                  '• Centro educativo asignado\n\n'
                  'No se recopilan fotografías reales, datos biométricos, direcciones, '
                  'teléfonos, datos de salud, DNI, fecha de nacimiento ni ningún otro '
                  'dato personal más allá de los indicados. El uso de avatares genéricos '
                  'en lugar de fotografías reales es una medida deliberada de protección '
                  'de la imagen del menor.',
            ),
            _buildSection(
              titleColor,
              '3. Finalidad del tratamiento',
              'Los datos se tratan exclusivamente con fines educativos:\n\n'
                  '• Evaluar el progreso académico del alumno en competencias básicas\n'
                  '• Proporcionar al profesorado información para adaptar la enseñanza\n'
                  '• Generar estadísticas de rendimiento académico individuales y grupales\n\n'
                  'Los datos nunca se utilizarán con fines comerciales, publicitarios '
                  'ni se compartirán con terceros ajenos al centro educativo.',
            ),
            _buildSection(
              titleColor,
              '4. Base legal del tratamiento',
              'El tratamiento de datos se fundamenta en:\n\n'
                  '• El ejercicio de la función docente y orientadora (Ley Orgánica de Educación)\n'
                  '• El consentimiento informado de los padres o tutores legales para menores de 14 años '
                  '(Art. 7 LOPDGDD)\n\n'
                  'El centro educativo es responsable de recabar y custodiar dicho consentimiento '
                  'antes de registrar a los alumnos en la aplicación. La app solicita confirmación '
                  'de este consentimiento al crear cada alumno.',
            ),
            _buildSection(
              titleColor,
              '5. Almacenamiento y seguridad',
              'Los datos se almacenan en Google Cloud Firestore (Firebase), con las siguientes '
                  'medidas de seguridad técnicas y organizativas:\n\n'
                  '• Transmisión cifrada mediante HTTPS/TLS\n'
                  '• Acceso restringido mediante autenticación por email y contraseña\n'
                  '• Política de contraseñas robusta (mínimo 8 caracteres, mayúsculas, '
                  'números y caracteres especiales)\n'
                  '• Verificación de correo electrónico obligatoria\n'
                  '• Aislamiento de datos por centro educativo (schoolId)\n'
                  '• Firebase App Check para verificar la legitimidad de las peticiones\n'
                  '• Reglas de seguridad en Firestore que impiden el acceso no autorizado\n'
                  '• Los resultados de actividades son inmutables (no pueden ser modificados)\n'
                  '• Registro de auditoría de todas las operaciones sobre datos de alumnos\n'
                  '• Cierre de sesión automático por inactividad (8 horas)\n'
                  '• Cabeceras de seguridad HTTP (CSP, X-Frame-Options, etc.)\n'
                  '• Sanitización de datos de entrada para prevenir inyecciones\n\n'
                  'Los servidores de Firebase cumplen con el RGPD.',
            ),
            _buildSection(
              titleColor,
              '6. Derechos de los interesados',
              'Los padres o tutores legales de los alumnos, así como los profesores, '
                  'pueden ejercer los siguientes derechos:\n\n'
                  '• Acceso: Conocer qué datos están almacenados (disponible en Configuración → Solicitar mis datos)\n'
                  '• Rectificación: Solicitar la corrección de datos incorrectos (editar alumno)\n'
                  '• Supresión: Solicitar la eliminación permanente de todos los datos '
                  '(eliminar alumno o eliminar cuenta completa)\n'
                  '• Oposición: Oponerse al tratamiento de los datos\n'
                  '• Portabilidad: Solicitar una copia de los datos en formato digital\n\n'
                  'La aplicación ofrece herramientas integradas para ejercer los derechos '
                  'de acceso, rectificación y supresión directamente desde la interfaz. '
                  'Para otros derechos, contacte con el centro educativo.',
            ),
            _buildSection(
              titleColor,
              '7. Conservación y retención de datos',
              'Los datos se conservarán mientras el alumno esté activo en el centro educativo.\n\n'
                  '• Los profesores pueden eliminar alumnos individual y permanentemente en cualquier momento\n'
                  '• La aplicación dispone de una herramienta de retención de datos que permite '
                  'eliminar automáticamente resultados antiguos (6 meses, 1 año o 2 años), '
                  'en cumplimiento del principio de minimización de datos (Art. 5.1.e RGPD)\n'
                  '• Al eliminar una cuenta de profesor, se eliminan todos los datos asociados '
                  '(alumnos y resultados) de forma permanente e irreversible\n'
                  '• Al solicitar la supresión de un alumno, se eliminan también todos sus '
                  'resultados de actividades (derecho al olvido, Art. 17 RGPD)',
            ),
            _buildSection(
              titleColor,
              '8. Menores de edad',
              'Esta aplicación trata datos de menores de 14 años. De conformidad con el artículo 7 '
                  'de la LOPDGDD:\n\n'
                  '• El tratamiento solo se realizará con el consentimiento verificable '
                  'de los padres o tutores legales\n'
                  '• El centro educativo es responsable de obtener y custodiar dicho consentimiento\n'
                  '• Se utiliza un sistema de avatares genéricos en lugar de fotografías reales '
                  'para proteger la imagen del menor\n'
                  '• Los datos recogidos se limitan al mínimo necesario para la finalidad educativa '
                  '(principio de minimización)',
            ),
            _buildSection(
              titleColor,
              '9. Contacto',
              'Para cualquier consulta relacionada con la protección de datos o para '
                  'ejercer los derechos indicados en esta política, puede dirigirse a:\n\n'
                  '• El profesor responsable del grupo del alumno\n'
                  '• La dirección del centro educativo\n'
                  '• El delegado de protección de datos del centro (si existe)\n\n'
                  'Asimismo, tiene derecho a presentar una reclamación ante la Agencia '
                  'Española de Protección de Datos (AEPD) en www.aepd.es si considera '
                  'que sus derechos no han sido debidamente atendidos.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(Color titleColor, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}