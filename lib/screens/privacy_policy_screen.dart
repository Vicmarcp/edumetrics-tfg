import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad de EduMetrics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Responsable del tratamiento',
              'EduMetrics es una aplicación educativa desarrollada como Proyecto de Fin de Ciclo. '
                  'El responsable del tratamiento de los datos es el centro educativo que utiliza la aplicación, '
                  'de acuerdo con el Reglamento General de Protección de Datos (RGPD) y la Ley Orgánica 3/2018 '
                  'de Protección de Datos Personales y garantía de los derechos digitales (LOPDGDD).',
            ),
            _buildSection(
              '2. Datos que recopilamos',
              'La aplicación recopila únicamente los siguientes datos de los alumnos:\n\n'
                  '• Nombre y apellidos (para identificación en el aula)\n'
                  '• Clase/grupo al que pertenece\n'
                  '• Avatar seleccionado (imagen genérica, no fotografía real)\n'
                  '• Resultados de las actividades educativas (aciertos, errores y tiempos de respuesta)\n\n'
                  'No se recopilan fotografías, datos biométricos, direcciones, teléfonos, '
                  'datos de salud ni ningún otro dato personal más allá de los indicados.',
            ),
            _buildSection(
              '3. Finalidad del tratamiento',
              'Los datos se tratan exclusivamente con fines educativos:\n\n'
                  '• Evaluar el progreso académico del alumno en competencias básicas\n'
                  '• Proporcionar al profesor información para adaptar la enseñanza\n'
                  '• Generar informes de rendimiento académico\n\n'
                  'Los datos nunca se utilizarán con fines comerciales, publicitarios '
                  'ni se compartirán con terceros ajenos al centro educativo.',
            ),
            _buildSection(
              '4. Base legal del tratamiento',
              'El tratamiento de datos se fundamenta en:\n\n'
                  '• El ejercicio de la función docente y orientadora (Ley Orgánica de Educación)\n'
                  '• El consentimiento informado de los padres o tutores legales para menores de 14 años '
                  '(Art. 7 LOPDGDD)\n\n'
                  'El centro educativo es responsable de recabar y custodiar dicho consentimiento '
                  'antes de registrar a los alumnos en la aplicación.',
            ),
            _buildSection(
              '5. Almacenamiento y seguridad',
              'Los datos se almacenan en Google Cloud Firestore (Firebase), con las siguientes medidas:\n\n'
                  '• Transmisión cifrada mediante HTTPS/TLS\n'
                  '• Acceso restringido mediante autenticación por email y contraseña\n'
                  '• Aislamiento de datos por centro educativo (schoolId)\n'
                  '• Solo los profesores autenticados del centro pueden acceder a los datos de sus alumnos\n\n'
                  'Los servidores de Firebase cumplen con el RGPD y se encuentran en la Unión Europea '
                  'cuando se configura la región correspondiente.',
            ),
            _buildSection(
              '6. Derechos de los interesados',
              'Los padres o tutores legales de los alumnos pueden ejercer los siguientes derechos:\n\n'
                  '• Acceso: Conocer qué datos de su hijo/a están almacenados\n'
                  '• Rectificación: Solicitar la corrección de datos incorrectos\n'
                  '• Supresión: Solicitar la eliminación permanente de todos los datos\n'
                  '• Oposición: Oponerse al tratamiento de los datos\n'
                  '• Portabilidad: Solicitar una copia de los datos en formato digital\n\n'
                  'Para ejercer estos derechos, contacte con el centro educativo o el profesor responsable.',
            ),
            _buildSection(
              '7. Conservación de datos',
              'Los datos se conservarán mientras el alumno esté activo en el centro educativo. '
                  'Al finalizar el curso o cuando el padre/tutor lo solicite, los datos serán eliminados '
                  'de forma permanente e irreversible.',
            ),
            _buildSection(
              '8. Menores de edad',
              'Esta aplicación trata datos de menores de 14 años. De conformidad con el artículo 7 '
                  'de la LOPDGDD, el tratamiento solo se realizará con el consentimiento verificable '
                  'de los padres o tutores legales. El centro educativo es responsable de obtener '
                  'y custodiar dicho consentimiento antes de utilizar la aplicación.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
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