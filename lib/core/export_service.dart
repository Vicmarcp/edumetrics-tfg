import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

import 'activity_names.dart';
import 'analytics_service.dart';

/// Servicio de exportación de datos a Excel y PDF.
class ExportService {
  /// Mapeo de claves de actividad a sus nombres legibles en español.
  /// Se delega a [kActivityNames] para permitir uso desde tests sin
  /// arrastrar dependencias web.
  static const Map<String, String> activityNames = kActivityNames;

  // ═══════════════════════════════════════════
  //  EXPORTAR ALUMNO INDIVIDUAL — EXCEL
  // ═══════════════════════════════════════════

  static Future<void> exportStudentToExcel({
    required String studentName,
    required List<QueryDocumentSnapshot> results,
  }) async {
    final excel = Excel.createExcel();

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
    );
    final errorStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#CC0000'),
      backgroundColorHex: ExcelColor.fromHexString('#FFE6E6'),
    );
    final correctStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#006600'),
    );

    // ── Hoja 1: Resultados ──
    final sheet = excel['Resultados'];
    final headerRow = [
      TextCellValue('Actividad'),
      TextCellValue('Pregunta'),
      TextCellValue('Respuesta correcta'),
      TextCellValue('Respuesta del alumno'),
      TextCellValue('Resultado'),
      TextCellValue('Tiempo (s)'),
      TextCellValue('Fecha'),
    ];
    sheet.appendRow(headerRow);
    for (var col = 0; col < headerRow.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    for (var i = 0; i < results.length; i++) {
      final data = results[i].data() as Map<String, dynamic>;
      final isCorrect = data['isCorrect'] as bool? ?? false;
      final timestamp = data['timestamp'] as Timestamp?;
      final dateStr = timestamp != null
          ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
          : '-';

      final rowData = [
        TextCellValue(
            activityNames[data['activityType']] ?? data['activityType'] ?? ''),
        TextCellValue(data['questionDetail']?.toString() ?? ''),
        TextCellValue(data['correctAnswer']?.toString() ?? ''),
        TextCellValue(data['userAnswer']?.toString() ?? ''),
        TextCellValue(isCorrect ? 'Correcto' : 'Incorrecto'),
        IntCellValue((data['timeSeconds'] as num?)?.toInt() ?? 0),
        TextCellValue(dateStr),
      ];
      sheet.appendRow(rowData);

      final style = isCorrect ? correctStyle : errorStyle;
      for (var col = 0; col < rowData.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: i + 1))
            .cellStyle = style;
      }
    }

    // ── Hoja 2: Resumen ──
    final summarySheet = excel['Resumen'];
    final summaryHeader = [
      TextCellValue('Actividad'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('Errores'),
      TextCellValue('% Aciertos'),
      TextCellValue('Tiempo medio (s)'),
    ];
    summarySheet.appendRow(summaryHeader);
    for (var col = 0; col < summaryHeader.length; col++) {
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      grouped.putIfAbsent(data['activityType'] as String? ?? '', () => [])
          .add(data);
    }

    var summaryRow = 1;
    for (final entry in grouped.entries) {
      final correct =
          entry.value.where((d) => d['isCorrect'] == true).length;
      final errors = entry.value.length - correct;
      final percent = entry.value.isEmpty
          ? 0
          : (correct * 100 / entry.value.length).round();
      final avgTime = entry.value.isEmpty
          ? 0
          : (entry.value.fold<int>(
          0,
              (t, d) =>
          t + ((d['timeSeconds'] as num?)?.toInt() ?? 0)) /
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

      if (percent < 50) {
        for (var col = 0; col < summaryHeader.length; col++) {
          summarySheet
              .cell(CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: summaryRow))
              .cellStyle = errorStyle;
        }
      }
      summaryRow++;
    }

    // ── Hoja 3: Errores ──
    final errorsSheet = excel['Errores'];
    final errorsHeader = [
      TextCellValue('Actividad'),
      TextCellValue('Pregunta'),
      TextCellValue('Respuesta correcta'),
      TextCellValue('Respuesta del alumno'),
      TextCellValue('Fecha'),
    ];
    errorsSheet.appendRow(errorsHeader);
    for (var col = 0; col < errorsHeader.length; col++) {
      errorsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    var errorRow = 1;
    for (final doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isCorrect'] == true) continue;

      final timestamp = data['timestamp'] as Timestamp?;
      errorsSheet.appendRow([
        TextCellValue(
            activityNames[data['activityType']] ?? data['activityType'] ?? ''),
        TextCellValue(data['questionDetail']?.toString() ?? ''),
        TextCellValue(data['correctAnswer']?.toString() ?? ''),
        TextCellValue(data['userAnswer']?.toString() ?? ''),
        TextCellValue(timestamp != null
            ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
            : '-'),
      ]);

      for (var col = 0; col < errorsHeader.length; col++) {
        errorsSheet
            .cell(CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: errorRow))
            .cellStyle = errorStyle;
      }
      errorRow++;
    }

    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    AnalyticsService.exportPerformed(
        type: 'student_excel', recordCount: results.length);

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadFile(
        Uint8List.fromList(bytes),
        'edumetrics_${_sanitizeFilename(studentName)}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  // ═══════════════════════════════════════════
  //  EXPORTAR ALUMNO INDIVIDUAL — PDF
  // ═══════════════════════════════════════════

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
      grouped.putIfAbsent(data['activityType'] as String? ?? '', () => [])
          .add(data);
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
              _statBox('Aciertos', '$totalCorrect'),
              _statBox('Errores', '$totalErrors'),
              _statBox('% Aciertos', '$totalPercent%'),
              _statBox('Tiempo medio', '${avgTime}s'),
            ],
          ),
          pw.SizedBox(height: 24),

          // Desglose por actividad
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
                  : (e.value.fold<int>(
                  0,
                      (t, d) =>
                  t +
                      ((d['timeSeconds'] as num?)?.toInt() ??
                          0)) /
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

          // Detalle de TODAS las respuestas con filas rojas para errores
          pw.Text('Detalle de todas las respuestas',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            pw.Container(
                width: 10,
                height: 10,
                decoration:
                const pw.BoxDecoration(color: PdfColors.red50)),
            pw.SizedBox(width: 4),
            pw.Text('Rojo = respuesta incorrecta',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.SizedBox(height: 8),
          pw.Table(
            border:
            pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Cabecera
              pw.TableRow(
                decoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  'Actividad',
                  'Pregunta',
                  'Correcta',
                  'Alumno',
                  'Result.',
                  'Fecha'
                ]
                    .map((h) =>
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                    ))
                    .toList(),
              ),
              // Filas de datos
              ...results.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isCorrect = data['isCorrect'] == true;
                final ts = data['timestamp'] as Timestamp?;
                final cells = [
                  activityNames[data['activityType']] ??
                      data['activityType'] ??
                      '',
                  data['questionDetail']?.toString() ?? '',
                  data['correctAnswer']?.toString() ?? '',
                  data['userAnswer']?.toString() ?? '',
                  isCorrect ? 'Correcto' : 'FALLO',
                  ts != null
                      ? DateFormat('dd/MM').format(ts.toDate())
                      : '-',
                ];

                return pw.TableRow(
                  decoration: isCorrect
                      ? null
                      : const pw.BoxDecoration(color: PdfColors.red50),
                  children: cells
                      .map((c) =>
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(c,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: isCorrect
                                  ? PdfColors.black
                                  : PdfColors.red800,
                              fontWeight: isCorrect
                                  ? pw.FontWeight.normal
                                  : pw.FontWeight.bold,
                            )),
                      ))
                      .toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );

    AnalyticsService.exportPerformed(
        type: 'student_pdf', recordCount: results.length);

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'edumetrics_${_sanitizeFilename(studentName)}.pdf',
    );
  }

  // ═══════════════════════════════════════════
  //  EXPORTAR CLASE — EXCEL
  // ═══════════════════════════════════════════

  static Future<void> exportClassToExcel({
    required String className,
    required Map<String, Map<String, dynamic>> studentData,
    required Map<String, Map<String, List<bool>>> activityData,
    required List<String> studentIds,
  }) async {
    final excel = Excel.createExcel();

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
    );
    final errorStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#CC0000'),
      backgroundColorHex: ExcelColor.fromHexString('#FFE6E6'),
    );

    // ── Hoja 1: Por alumno ──
    final summarySheet = excel['Por alumno'];
    final summaryHeader = [
      TextCellValue('Alumno'),
      TextCellValue('Clase'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('Errores'),
      TextCellValue('% Aciertos'),
    ];
    summarySheet.appendRow(summaryHeader);
    for (var col = 0; col < summaryHeader.length; col++) {
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    var row = 1;
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

      if (percent < 50) {
        for (var col = 0; col < summaryHeader.length; col++) {
          summarySheet
              .cell(CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: row))
              .cellStyle = errorStyle;
        }
      }
      row++;
    }

    // ── Hoja 2: Por actividad ──
    final actSheet = excel['Por actividad'];
    final actHeader = [
      TextCellValue('Actividad'),
      TextCellValue('Respuestas'),
      TextCellValue('Aciertos'),
      TextCellValue('Errores'),
      TextCellValue('% Aciertos'),
    ];
    actSheet.appendRow(actHeader);
    for (var col = 0; col < actHeader.length; col++) {
      actSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    final Map<String, List<bool>> aggregated = {};
    for (final id in studentIds) {
      final activities = activityData[id];
      if (activities == null) continue;
      for (final entry in activities.entries) {
        aggregated.putIfAbsent(entry.key, () => []).addAll(entry.value);
      }
    }

    var actRow = 1;
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

      if (percent < 50) {
        for (var col = 0; col < actHeader.length; col++) {
          actSheet
              .cell(CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: actRow))
              .cellStyle = errorStyle;
        }
      }
      actRow++;
    }

    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    AnalyticsService.exportPerformed(
        type: 'class_excel', recordCount: studentIds.length);

    final bytes = excel.encode();
    if (bytes != null) {
      _downloadFile(
        Uint8List.fromList(bytes),
        'edumetrics_clase_${_sanitizeFilename(className)}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  // ═══════════════════════════════════════════
  //  EXPORTAR CLASE — PDF
  // ═══════════════════════════════════════════

  static Future<void> exportClassToPdf({
    required String className,
    required Map<String, Map<String, dynamic>> studentData,
    required Map<String, Map<String, List<bool>>> activityData,
    required List<String> studentIds,
  }) async {
    final pdf = pw.Document();

    final List<_StudentRow> studentRows = [];
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
      studentRows.add(_StudentRow(
        cells: [
          name,
          cls,
          '${allResults.length}',
          '$correct',
          '$errors',
          '$percent%'
        ],
        percent: percent,
      ));
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
          pw.SizedBox(height: 4),
          pw.Row(children: [
            pw.Container(
                width: 10,
                height: 10,
                decoration:
                const pw.BoxDecoration(color: PdfColors.red50)),
            pw.SizedBox(width: 4),
            pw.Text('Rojo = menos del 50% de aciertos',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.SizedBox(height: 8),
          pw.Table(
            border:
            pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  'Alumno',
                  'Clase',
                  'Total',
                  'Aciertos',
                  'Errores',
                  '% Aciertos'
                ]
                    .map((h) =>
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                    ))
                    .toList(),
              ),
              ...studentRows.map((sr) =>
                  pw.TableRow(
                    decoration: sr.percent < 50
                        ? const pw.BoxDecoration(color: PdfColors.red50)
                        : null,
                    children: sr.cells
                        .map((c) =>
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(c,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: sr.percent < 50
                                    ? PdfColors.red800
                                    : PdfColors.black,
                                fontWeight: sr.percent < 50
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                              )),
                        ))
                        .toList(),
                  )),
            ],
          ),
          pw.SizedBox(height: 24),

          pw.Text('Dificultad por actividad',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border:
            pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  'Actividad',
                  'Respuestas',
                  'Aciertos',
                  'Errores',
                  '% Aciertos'
                ]
                    .map((h) =>
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                    ))
                    .toList(),
              ),
              ...aggregated.entries.map((e) {
                final correct = e.value
                    .where((r) => r)
                    .length;
                final errors = e.value.length - correct;
                final percent = e.value.isEmpty
                    ? 0
                    : (correct * 100 / e.value.length).round();
                final cells = [
                  activityNames[e.key] ?? e.key,
                  '${e.value.length}',
                  '$correct',
                  '$errors',
                  '$percent%',
                ];
                return pw.TableRow(
                  decoration: percent < 50
                      ? const pw.BoxDecoration(color: PdfColors.red50)
                      : null,
                  children: cells
                      .map((c) =>
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(c,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: percent < 50
                                  ? PdfColors.red800
                                  : PdfColors.black,
                              fontWeight: percent < 50
                                  ? pw.FontWeight.bold
                                  : pw.FontWeight.normal,
                            )),
                      ))
                      .toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );

    AnalyticsService.exportPerformed(
        type: 'class_pdf', recordCount: studentIds.length);

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
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor =
    web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  static String _sanitizeFilename(String name) {
    return name
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }
}

class _StudentRow {
  final List<String> cells;
  final int percent;

  _StudentRow({required this.cells, required this.percent});
}