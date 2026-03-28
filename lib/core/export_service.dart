import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Servicio de exportación de datos a Excel y PDF.
class ExportService {
  static const Map<String, String> activityNames = {
    'comparison': 'Comparación',
    'sequence': 'Secuencia',
    'place_value': 'Valor Posicional',
    'addition': 'Sumas',
    'subtraction': 'Restas',
    'missing_vowels': 'Vocales',
    'syllable_count': 'Sílabas',
    'sentence_order': 'Ordenar Frases',
    'capitalization': 'Mayúsculas',
    'syllable_complete': 'Completar Sílabas',
  };

  // ═══════════════════════════════════════════
  //  EXPORTAR ALUMNO INDIVIDUAL
  // ═══════════════════════════════════════════

  static Future<void> exportStudentToExcel({
    required String studentName,
    required List<QueryDocumentSnapshot> results,
  }) async {
    final excel = Excel.createExcel();

    // Hoja 1: Detalle completo
    final sheet = excel['Resultados'];
    sheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Pregunta'),
      TextCellValue('Respuesta correcta'),
      TextCellValue('Respuesta del alumno'),
      TextCellValue('Resultado'),
      TextCellValue('Tiempo (s)'),
      TextCellValue('Fecha'),
    ]);

    for (final doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      final activityType = data['activityType'] as String? ?? '';
      final isCorrect = data['isCorrect'] as bool? ?? false;
      final timeSeconds = (data['timeSeconds'] as num?)?.toInt() ?? 0;
      final timestamp = data['timestamp'] as Timestamp?;
      final dateStr = timestamp != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
          : '-';
      final questionDetail = data['questionDetail'] as String? ?? '';
      final correctAnswer = data['correctAnswer']?.toString() ?? '';
      final userAnswer = data['userAnswer']?.toString() ?? '';

      sheet.appendRow([
        TextCellValue(activityNames[activityType] ?? activityType),
        TextCellValue(questionDetail),
        TextCellValue(correctAnswer),
        TextCellValue(userAnswer),
        TextCellValue(isCorrect ? 'Correcto' : 'Incorrecto'),
        IntCellValue(timeSeconds),
        TextCellValue(dateStr),
      ]);
    }

    // Hoja 2: Resumen por actividad
    final summarySheet = excel['Resumen'];
    summarySheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('Errores'),
      TextCellValue('% Aciertos'),
      TextCellValue('Tiempo medio (s)'),
    ]);

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? '';
      grouped.putIfAbsent(type, () => []).add(data);
    }

    for (final entry in grouped.entries) {
      final correct =
          entry.value.where((d) => d['isCorrect'] == true).length;
      final errors = entry.value.length - correct;
      final percent = entry.value.isEmpty
          ? 0
          : (correct * 100 / entry.value.length).round();
      final avgTime = entry.value.isEmpty
          ? 0
          : (entry.value.fold<int>(0,
              (t, d) => t + ((d['timeSeconds'] as num?)?.toInt() ?? 0)) /
          entry.value.length)
          .round();

      summarySheet.appendRow([
        TextCellValue(activityNames[entry.key] ?? entry.key),
        IntCellValue(entry.value.length),
        IntCellValue(correct),
        IntCellValue(errors),
        TextCellValue('$percent%'),
        IntCellValue(avgTime),
      ]);
    }

    // Hoja 3: Errores detallados
    final errorsSheet = excel['Errores'];
    errorsSheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Pregunta'),
      TextCellValue('Respuesta correcta'),
      TextCellValue('Respuesta del alumno'),
      TextCellValue('Fecha'),
    ]);

    for (final doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isCorrect'] == true) continue;

      final activityType = data['activityType'] as String? ?? '';
      final timestamp = data['timestamp'] as Timestamp?;
      final dateStr = timestamp != null
          ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
          : '-';

      errorsSheet.appendRow([
        TextCellValue(activityNames[activityType] ?? activityType),
        TextCellValue(data['questionDetail']?.toString() ?? ''),
        TextCellValue(data['correctAnswer']?.toString() ?? ''),
        TextCellValue(data['userAnswer']?.toString() ?? ''),
        TextCellValue(dateStr),
      ]);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadFile(
        Uint8List.fromList(bytes),
        'edumetrics_${_sanitizeFilename(studentName)}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static Future<void> exportStudentToPdf({
    required String studentName,
    required List<QueryDocumentSnapshot> results,
  }) async {
    final pdf = pw.Document();

    final totalCorrect = results.where((r) {
      final data = r.data() as Map<String, dynamic>;
      return data['isCorrect'] == true;
    }).length;
    final totalErrors = results.length - totalCorrect;
    final totalPercent =
    results.isEmpty ? 0 : (totalCorrect * 100 / results.length).round();
    final avgTime = results.isEmpty
        ? 0
        : (results.fold<int>(0, (total, r) {
      final data = r.data() as Map<String, dynamic>;
      return total + ((data['timeSeconds'] as num?)?.toInt() ?? 0);
    }) /
        results.length)
        .round();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final result in results) {
      final data = result.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? '';
      grouped.putIfAbsent(type, () => []).add(data);
    }

    final errors = results.where((r) {
      final data = r.data() as Map<String, dynamic>;
      return data['isCorrect'] != true;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader('Informe Individual', studentName),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _statBox('Total', '${results.length}'),
              _statBox('Aciertos', '$totalCorrect'),
              _statBox('Errores', '$totalErrors'),
              _statBox('% Aciertos', '$totalPercent%'),
              _statBox('Tiempo medio', '${avgTime}s'),
            ],
          ),
          pw.SizedBox(height: 24),

          pw.Text('Desglose por actividad',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              'Actividad',
              'Total',
              'Aciertos',
              'Errores',
              '% Aciertos',
              'T. medio'
            ],
            data: grouped.entries.map((e) {
              final correct =
                  e.value.where((d) => d['isCorrect'] == true).length;
              final actErrors = e.value.length - correct;
              final percent = e.value.isEmpty
                  ? 0
                  : (correct * 100 / e.value.length).round();
              final actAvgTime = e.value.isEmpty
                  ? 0
                  : (e.value.fold<int>(0,
                      (t, d) => t + ((d['timeSeconds'] as num?)?.toInt() ?? 0)) /
                  e.value.length)
                  .round();
              return [
                activityNames[e.key] ?? e.key,
                '${e.value.length}',
                '$correct',
                '$actErrors',
                '$percent%',
                '${actAvgTime}s',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          // Detalle de TODAS las respuestas
          pw.SizedBox(height: 24),
          pw.Text('Detalle de todas las respuestas',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.grey300),
            headers: [
              'Actividad',
              'Pregunta',
              'Correcta',
              'Alumno',
              'Resultado',
              'Fecha'
            ],
            data: results.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              return [
                activityNames[data['activityType']] ??
                    data['activityType'] ??
                    '',
                data['questionDetail']?.toString() ?? '',
                data['correctAnswer']?.toString() ?? '',
                data['userAnswer']?.toString() ?? '',
                data['isCorrect'] == true ? 'Correcto' : 'FALLO',
                ts != null
                    ? DateFormat('dd/MM/yyyy').format(ts.toDate())
                    : '-',
              ];
            }).toList(),
          ),

          // Resumen de errores
          if (errors.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Resumen de errores (${errors.length})',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700)),
            pw.SizedBox(height: 4),
            pw.Text(
                'Preguntas que el alumno ha respondido incorrectamente:',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
              const pw.BoxDecoration(color: PdfColors.red50),
              headers: [
                'Actividad',
                'Pregunta',
                'Correcta',
                'Alumno',
                'Fecha'
              ],
              data: errors.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                return [
                  activityNames[data['activityType']] ??
                      data['activityType'] ??
                      '',
                  data['questionDetail']?.toString() ?? '',
                  data['correctAnswer']?.toString() ?? '',
                  data['userAnswer']?.toString() ?? '',
                  ts != null
                      ? DateFormat('dd/MM/yyyy').format(ts.toDate())
                      : '-',
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'edumetrics_${_sanitizeFilename(studentName)}.pdf',
    );
  }

  // ═══════════════════════════════════════════
  //  EXPORTAR CLASE
  // ═══════════════════════════════════════════

  static Future<void> exportClassToExcel({
    required String className,
    required Map<String, Map<String, dynamic>> studentData,
    required Map<String, Map<String, List<bool>>> activityData,
    required List<String> studentIds,
  }) async {
    final excel = Excel.createExcel();

    final summarySheet = excel['Por alumno'];
    summarySheet.appendRow([
      TextCellValue('Alumno'),
      TextCellValue('Clase'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('Errores'),
      TextCellValue('% Aciertos'),
    ]);

    for (final id in studentIds) {
      final name = studentData[id]?['name'] ?? '?';
      final cls = studentData[id]?['className'] ?? '';
      final activities = activityData[id];
      if (activities == null) continue;

      final allResults = activities.values.expand((e) => e).toList();
      final correct = allResults.where((r) => r).length;
      final errors = allResults.length - correct;
      final percent = allResults.isEmpty
          ? 0
          : (correct * 100 / allResults.length).round();

      summarySheet.appendRow([
        TextCellValue(name),
        TextCellValue(cls),
        IntCellValue(allResults.length),
        IntCellValue(correct),
        IntCellValue(errors),
        TextCellValue('$percent%'),
      ]);
    }

    final actSheet = excel['Por actividad'];
    actSheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('Errores'),
      TextCellValue('% Aciertos'),
    ]);

    final Map<String, List<bool>> aggregated = {};
    for (final id in studentIds) {
      final activities = activityData[id];
      if (activities == null) continue;
      for (final entry in activities.entries) {
        aggregated.putIfAbsent(entry.key, () => []).addAll(entry.value);
      }
    }

    for (final entry in aggregated.entries) {
      final correct = entry.value.where((r) => r).length;
      final errors = entry.value.length - correct;
      final percent = entry.value.isEmpty
          ? 0
          : (correct * 100 / entry.value.length).round();
      actSheet.appendRow([
        TextCellValue(activityNames[entry.key] ?? entry.key),
        IntCellValue(entry.value.length),
        IntCellValue(correct),
        IntCellValue(errors),
        TextCellValue('$percent%'),
      ]);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadFile(
        Uint8List.fromList(bytes),
        'edumetrics_clase_${_sanitizeFilename(className)}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static Future<void> exportClassToPdf({
    required String className,
    required Map<String, Map<String, dynamic>> studentData,
    required Map<String, Map<String, List<bool>>> activityData,
    required List<String> studentIds,
  }) async {
    final pdf = pw.Document();

    final List<List<String>> studentRows = [];
    for (final id in studentIds) {
      final name = studentData[id]?['name'] ?? '?';
      final cls = studentData[id]?['className'] ?? '';
      final activities = activityData[id];
      if (activities == null) continue;

      final allResults = activities.values.expand((e) => e).toList();
      final correct = allResults.where((r) => r).length;
      final errors = allResults.length - correct;
      final percent = allResults.isEmpty
          ? 0
          : (correct * 100 / allResults.length).round();
      studentRows.add(
          [
            name,
            cls,
            '${allResults.length}',
            '$correct',
            '$errors',
            '$percent%'
          ]);
    }

    final Map<String, List<bool>> aggregated = {};
    for (final id in studentIds) {
      final activities = activityData[id];
      if (activities == null) continue;
      for (final entry in activities.entries) {
        aggregated.putIfAbsent(entry.key, () => []).addAll(entry.value);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader('Informe de Clase', className),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _statBox('Alumnos', '${studentRows.length}'),
              _statBox('Actividades', '${aggregated.length}'),
            ],
          ),
          pw.SizedBox(height: 24),

          pw.Text('Rendimiento por alumno',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.grey300),
            headers: [
              'Alumno',
              'Clase',
              'Total',
              'Aciertos',
              'Errores',
              '% Aciertos'
            ],
            data: studentRows,
          ),
          pw.SizedBox(height: 24),

          pw.Text('Dificultad por actividad',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.grey300),
            headers: [
              'Actividad',
              'Respuestas',
              'Aciertos',
              'Errores',
              '% Aciertos'
            ],
            data: aggregated.entries.map((e) {
              final correct = e.value.where((r) => r).length;
              final errors = e.value.length - correct;
              final percent = e.value.isEmpty
                  ? 0
                  : (correct * 100 / e.value.length).round();
              return [
                activityNames[e.key] ?? e.key,
                '${e.value.length}',
                '$correct',
                '$errors',
                '$percent%',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'edumetrics_clase_${_sanitizeFilename(className)}.pdf',
    );
  }

  // ═══════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════

  static pw.Widget _buildPdfHeader(String reportType, String name) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(width: 2, color: PdfColors.deepPurple)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('EduMetrics',
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple)),
              pw.Text(reportType,
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(name,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static void _downloadFile(
      Uint8List bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String _sanitizeFilename(String name) {
    return name
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }
}