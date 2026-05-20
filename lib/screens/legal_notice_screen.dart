import 'package:flutter/material.dart';

class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso Legal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title('1. Información general'),
            _P(
              'En cumplimiento del artículo 10 de la Ley 34/2002, de 11 de julio, '
              'de Servicios de la Sociedad de la Información y Comercio Electrónico '
              '(LSSI-CE), se informa de los siguientes datos:',
            ),
            _P('• Titular: Víctor Marcos Peña'),
            _P('• Dirección: Disponible bajo solicitud'),
            _P('• Email de contacto: victormarcosp@gmail.com'),
            _P(
              '• Naturaleza: Trabajo de Fin de Grado (TFG) — '
              'Desarrollo de Aplicaciones Multiplataforma (DAM)',
            ),
            _P('• Centro académico: Universidad Alfonso X el Sabio (UAX)'),
            _P('• URL: https://edumetrics-tfg.web.app'),

            _Title('2. Objeto'),
            _P(
              'EduMetrics es una aplicación web educativa desarrollada como TFG '
              'destinada a profesores de Educación Primaria para evaluar competencias '
              'matemáticas y de lenguaje en alumnos de 1º de Primaria mediante '
              'actividades interactivas en pizarras digitales.',
            ),

            _Title('3. Condiciones de acceso'),
            _P(
              'El acceso a la aplicación está restringido a profesores autorizados '
              'mediante credenciales individuales proporcionadas por el administrador. '
              'No está permitido el registro libre.',
            ),
            _P(
              'El usuario se compromete a hacer un uso adecuado y lícito de la '
              'aplicación, con sujeción a la normativa vigente, en particular la '
              'relacionada con la protección de datos de menores.',
            ),

            _Title('4. Propiedad intelectual'),
            _P(
              'El código fuente, diseño, logotipos, textos, gráficos y cualquier '
              'otro contenido de EduMetrics son propiedad del autor del TFG, salvo '
              'aquellos elementos cuya autoría se atribuye expresamente a terceros '
              '(librerías open source, fuentes tipográficas, etc.).',
            ),
            _P(
              'Las librerías de software utilizadas (Flutter, Firebase, fl_chart, '
              'flutter_tts, audioplayers, OpenDyslexic, entre otras) están sujetas '
              'a sus respectivas licencias.',
            ),

            _Title('5. Responsabilidad'),
            _P(
              'EduMetrics se proporciona "tal cual" como ejercicio académico. '
              'El autor no garantiza la disponibilidad continua del servicio ni '
              'se hace responsable de eventuales errores, pérdidas de datos o '
              'consecuencias derivadas del uso de la aplicación en entornos '
              'reales sin la debida adaptación.',
            ),

            _Title('6. Protección de datos'),
            _P(
              'El tratamiento de datos personales se rige por la Política de '
              'Privacidad disponible en la propia aplicación, conforme al '
              'Reglamento (UE) 2016/679 (RGPD) y la Ley Orgánica 3/2018 de '
              'Protección de Datos Personales y Garantía de los Derechos Digitales '
              '(LOPDGDD).',
            ),

            _Title('7. Legislación aplicable'),
            _P(
              'Las presentes condiciones se rigen por la legislación española. '
              'Para cualquier controversia que pudiera derivarse del uso de la '
              'aplicación, las partes se someten a los Juzgados y Tribunales del '
              'domicilio del titular.',
            ),

            _Title('8. Modificaciones'),
            _P(
              'El titular se reserva el derecho a modificar este aviso legal en '
              'cualquier momento. Los cambios entrarán en vigor desde su '
              'publicación en la aplicación.',
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
