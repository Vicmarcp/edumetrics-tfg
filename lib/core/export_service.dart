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

  /// Exporta los resultados de un alumno a Excel (.xlsx)
  static Future<void> exportStudentToExcel({
    required String studentName,
    required List<QueryDocumentSnapshot> results,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Resultados'];

    // Cabeceras
    sheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Resultado'),
      TextCellValue('Tiempo (s)'),
      TextCellValue('Fecha'),
    ]);

    // Datos
    for (final doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      final activityType = data['activityType'] as String? ?? '';
      final isCorrect = data['isCorrect'] as bool? ?? false;
      final timeSeconds = (data['timeSeconds'] as num?)?.toInt() ?? 0;
      final timestamp = data['timestamp'] as Timestamp?;
      final dateStr = timestamp != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
          : '-';

      sheet.appendRow([
        TextCellValue(activityNames[activityType] ?? activityType),
        TextCellValue(isCorrect ? 'Correcto' : 'Incorrecto'),
        IntCellValue(timeSeconds),
        TextCellValue(dateStr),
      ]);
    }

    // Hoja resumen por actividad
    final summarySheet = excel['Resumen'];
    summarySheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
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
      final percent = entry.value.isEmpty
          ? 0
          : (correct * 100 / entry.value.length).round();
      final avgTime = entry.value.isEmpty
          ? 0
          : (entry.value.fold<int>(
          0, (t, d) => t + ((d['timeSeconds'] as num?)?.toInt() ?? 0)) /
          entry.value.length)
          .round();

      summarySheet.appendRow([
        TextCellValue(activityNames[entry.key] ?? entry.key),
        IntCellValue(entry.value.length),
        IntCellValue(correct),
        TextCellValue('$percent%'),
        IntCellValue(avgTime),
      ]);
    }

    // Eliminar hoja por defecto
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

  /// Exporta los resultados de un alumno a PDF
  static Future<void> exportStudentToPdf({
    required String studentName,
    required List<QueryDocumentSnapshot> results,
  }) async {
    final pdf = pw.Document();

    // Calcular estadísticas
    final totalCorrect = results.where((r) {
      final data = r.data() as Map<String, dynamic>;
      return data['isCorrect'] == true;
    }).length;
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

    // Agrupar por actividad
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final result in results) {
      final data = result.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? '';
      grouped.putIfAbsent(type, () => []).add(data);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader('Informe Individual', studentName),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Resumen
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _statBox('Total', '${results.length}'),
              _statBox('Aciertos', '$totalPercent%'),
              _statBox('Tiempo medio', '${avgTime}s'),
              _statBox('Actividades', '${grouped.length}'),
            ],
          ),
          pw.SizedBox(height: 24),

          // Tabla por actividad
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
              'Respuestas',
              'Aciertos',
              '% Aciertos',
              'Tiempo medio'
            ],
            data: grouped.entries.map((e) {
              final correct =
                  e.value.where((d) => d['isCorrect'] == true).length;
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
                '$percent%',
                '${actAvgTime}s',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          // Tabla detallada
          pw.Text('Detalle de resultados',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.grey300),
            headers: ['Actividad', 'Resultado', 'Tiempo', 'Fecha'],
            data: results.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              return [
                activityNames[data['activityType']] ??
                    data['activityType'] ??
                    '',
                data['isCorrect'] == true ? 'Correcto' : 'Incorrecto',
                '${(data['timeSeconds'] as num?)?.toInt() ?? 0}s',
                ts != null
                    ? DateFormat('dd/MM/yyyy').format(ts.toDate())
                    : '-',
              ];
            }).toList(),
          ),
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

  /// Exporta las estadísticas de clase a Excel (.xlsx)
  static Future<void> exportClassToExcel({
    required String className,
    required Map<String, Map<String, dynamic>> studentData,
    required Map<String, Map<String, List<bool>>> activityData,
    required List<String> studentIds,
  }) async {
    final excel = Excel.createExcel();

    // Hoja 1: Resumen por alumno
    final summarySheet = excel['Por alumno'];
    summarySheet.appendRow([
      TextCellValue('Alumno'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('% Aciertos'),
    ]);

    for (final id in studentIds) {
      final name = studentData[id]?['name'] ?? '?';
      final activities = activityData[id];
      if (activities == null) continue;

      final allResults = activities.values.expand((e) => e).toList();
      final correct = allResults.where((r) => r).length;
      final percent = allResults.isEmpty
          ? 0
          : (correct * 100 / allResults.length).round();

      summarySheet.appendRow([
        TextCellValue(name),
        IntCellValue(allResults.length),
        IntCellValue(correct),
        TextCellValue('$percent%'),
      ]);
    }

    // Hoja 2: Por actividad
    final actSheet = excel['Por actividad'];
    actSheet.appendRow([
      TextCellValue('Actividad'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
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
      final percent = entry.value.isEmpty
          ? 0
          : (correct * 100 / entry.value.length).round();
      actSheet.appendRow([
        TextCellValue(activityNames[entry.key] ?? entry.key),
        IntCellValue(entry.value.length),
        IntCellValue(correct),
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

  /// Exporta las estadísticas de clase a PDF
  static Future<void> exportClassToPdf({
    required String className,
    required Map<String, Map<String, dynamic>> studentData,
    required Map<String, Map<String, List<bool>>> activityData,
    required List<String> studentIds,
  }) async {
    final pdf = pw.Document();

    // Datos por alumno
    final List<List<String>> studentRows = [];
    for (final id in studentIds) {
      final name = studentData[id]?['name'] ?? '?';
      final activities = activityData[id];
      if (activities == null) continue;

      final allResults = activities.values.expand((e) => e).toList();
      final correct = allResults.where((r) => r).length;
      final percent = allResults.isEmpty
          ? 0
          : (correct * 100 / allResults.length).round();
      studentRows
          .add([name, '${allResults.length}', '$correct', '$percent%']);
    }

    // Datos por actividad
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
            headers: ['Alumno', 'Respuestas', 'Aciertos', '% Aciertos'],
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
            headers: ['Actividad', 'Respuestas', 'Aciertos', '% Aciertos'],
            data: aggregated.entries.map((e) {
              final correct = e.value.where((r) => r).length;
              final percent = e.value.isEmpty
                  ? 0
                  : (correct * 100 / e.value.length).round();
              return [
                activityNames[e.key] ?? e.key,
                '${e.value.length}',
                '$correct',
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
            bottom:
            pw.BorderSide(width: 2, color: PdfColors.deepPurple)),
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