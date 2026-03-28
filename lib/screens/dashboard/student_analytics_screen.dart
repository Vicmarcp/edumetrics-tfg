import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/export_service.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String schoolId;

  const StudentAnalyticsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.schoolId,
  });

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  List<QueryDocumentSnapshot> _allResults = [];
  List<QueryDocumentSnapshot> _filteredResults = [];
  bool _loading = true;
  String? _errorMessage;

  // Filtro de fecha
  String _selectedFilter = 'todo';
  DateTimeRange? _customRange;

  static const Map<String, String> activityNames = {
    'comparison': 'Comparación',
    'sequence': 'Secuencia',
    'place_value': 'Valor Pos.',
    'addition': 'Sumas',
    'subtraction': 'Restas',
    'missing_vowels': 'Vocales',
    'syllable_count': 'Sílabas',
    'sentence_order': 'Ord. Frases',
    'capitalization': 'Mayúsculas',
    'syllable_complete': 'Comp. Síl.',
  };

  static const List<Color> activityColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.deepPurple,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('schoolId', isEqualTo: widget.schoolId)
          .where('studentId', isEqualTo: widget.studentId)
          .orderBy('timestamp', descending: false)
          .get();

      if (mounted) {
        setState(() {
          _allResults = snapshot.docs;
          _applyDateFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyDateFilter() {
    final now = DateTime.now();
    DateTime? start;

    switch (_selectedFilter) {
      case 'semana':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'mes':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'trimestre':
        start = DateTime(now.year, now.month - 2, 1);
        break;
      case 'personalizado':
        if (_customRange != null) {
          _filteredResults = _allResults.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['timestamp'] as Timestamp?;
            if (ts == null) return false;
            final date = ts.toDate();
            return date.isAfter(
                _customRange!.start.subtract(const Duration(days: 1))) &&
                date.isBefore(
                    _customRange!.end.add(const Duration(days: 1)));
          }).toList();
          return;
        }
        _filteredResults = _allResults;
        return;
      default:
        _filteredResults = _allResults;
        return;
    }


      _filteredResults = _allResults.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['timestamp'] as Timestamp?;
        if (ts == null) return false;
        return ts.toDate().isAfter(start!.subtract(const Duration(seconds: 1)));
      }).toList();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyDateFilter();
    });
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona un rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );

    if (range != null) {
      setState(() {
        _customRange = range;
        _selectedFilter = 'personalizado';
        _applyDateFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas: ${widget.studentName}'),
        actions: [
          if (_filteredResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.table_chart, size: 18),
                label: const Text('Excel'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  foregroundColor: Colors.green,
                ),
                onPressed: () {
                  ExportService.exportStudentToExcel(
                    studentName: widget.studentName,
                    results: _filteredResults,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  foregroundColor: Colors.red,
                ),
                onPressed: () {
                  ExportService.exportStudentToPdf(
                    studentName: widget.studentName,
                    results: _filteredResults,
                  );
                },
              ),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error al cargar resultados',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _errorMessage = null;
                  });
                  _loadResults();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Este alumno aún no tiene resultados',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Los resultados aparecerán tras completar actividades',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filtro de fechas ──
          _DateFilterBar(
            selected: _selectedFilter,
            customRange: _customRange,
            onChanged: _onFilterChanged,
            onPickRange: _pickCustomRange,
          ),
          const SizedBox(height: 8),
          if (_filteredResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('No hay resultados en el periodo seleccionado',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            )
          else ...[
            _buildSummaryCards(context),
            const SizedBox(height: 24),
            _buildSectionTitle(
                context, 'Porcentaje de aciertos por actividad'),
            const SizedBox(height: 8),
            SizedBox(height: 300, child: _buildAccuracyChart(context)),
            const SizedBox(height: 32),
            _buildSectionTitle(
                context, 'Evolución temporal del rendimiento'),
            const SizedBox(height: 8),
            SizedBox(height: 300, child: _buildEvolutionChart(context)),
            const SizedBox(height: 32),
            _buildSectionTitle(
                context, 'Tiempo medio por pregunta (segundos)'),
            const SizedBox(height: 8),
            SizedBox(height: 300, child: _buildTimeChart(context)),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final results = _filteredResults;
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

    final activities = results
        .map((r) => (r.data() as Map<String, dynamic>)['activityType'])
        .toSet()
        .length;

    return Row(
      children: [
        _summaryCard(
            context, 'Total respuestas', '${results.length}', Colors.blue),
        const SizedBox(width: 12),
        _summaryCard(context, '% Aciertos', '$totalPercent%', Colors.green),
        const SizedBox(width: 12),
        _summaryCard(context, 'Tiempo medio', '${avgTime}s', Colors.orange),
        const SizedBox(width: 12),
        _summaryCard(context, 'Actividades', '$activities', Colors.purple),
      ],
    );
  }

  Widget _summaryCard(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface));
  }

  Widget _buildAccuracyChart(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface;
    final gridColor = Theme.of(context).dividerColor;

    final Map<String, List<bool>> grouped = {};
    for (final result in _filteredResults) {
      final data = result.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? 'unknown';
      final correct = data['isCorrect'] as bool? ?? false;
      grouped.putIfAbsent(type, () => []).add(correct);
    }

    final types =
    activityNames.keys.where((k) => grouped.containsKey(k)).toList();
    if (types.isEmpty) return const Center(child: Text('Sin datos'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final type = types[group.x.toInt()];
              return BarTooltipItem(
                '${activityNames[type]}\n${rod.toY.round()}%',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= types.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  angle: -0.5,
                  child: Text(activityNames[types[idx]] ?? types[idx],
                      style: TextStyle(fontSize: 11, color: labelColor)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: labelColor)),
            ),
          ),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: types.asMap().entries.map((entry) {
          final results = grouped[entry.value]!;
          final correct = results.where((r) => r).length;
          final percent =
          results.isEmpty ? 0.0 : correct * 100 / results.length;
          final colorIdx = activityNames.keys.toList().indexOf(entry.value);
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: percent,
                color: activityColors[colorIdx % activityColors.length],
                width: 22,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEvolutionChart(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface;
    final gridColor = Theme.of(context).dividerColor;

    if (_filteredResults.length < 5) {
      return const Center(
          child: Text(
              'Se necesitan al menos 5 respuestas para ver la evolución'));
    }

    final List<FlSpot> spots = [];
    final blockSize = _filteredResults.length < 10 ? 5 : 10;
    final blocks = _filteredResults.length ~/ blockSize;

    for (int i = 0; i < blocks; i++) {
      final block =
      _filteredResults.sublist(i * blockSize, (i + 1) * blockSize);
      final correct = block.where((r) {
        final data = r.data() as Map<String, dynamic>;
        return data['isCorrect'] == true;
      }).length;
      spots.add(FlSpot(i.toDouble(), correct * 100 / blockSize));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) => LineTooltipItem(
                  'Sesión ${spot.x.toInt() + 1}: ${spot.y.round()}%',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)))
                  .toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Sesiones',
                style: TextStyle(fontSize: 12, color: labelColor)),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                  '${value.toInt() + 1}',
                  style: TextStyle(fontSize: 10, color: labelColor)),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: labelColor)),
            ),
          ),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
            show: true, border: Border.all(color: gridColor)),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChart(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface;
    final gridColor = Theme.of(context).dividerColor;

    final Map<String, List<int>> grouped = {};
    for (final result in _filteredResults) {
      final data = result.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? 'unknown';
      final time = (data['timeSeconds'] as num?)?.toInt() ?? 0;
      grouped.putIfAbsent(type, () => []).add(time);
    }

    final types =
    activityNames.keys.where((k) => grouped.containsKey(k)).toList();
    if (types.isEmpty) return const Center(child: Text('Sin datos'));

    final maxTime = grouped.values
        .expand((e) => e)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxTime + 2).clamp(5, 60),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final type = types[group.x.toInt()];
              return BarTooltipItem(
                '${activityNames[type]}\n${rod.toY.toStringAsFixed(1)}s',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= types.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  angle: -0.5,
                  child: Text(activityNames[types[idx]] ?? types[idx],
                      style: TextStyle(fontSize: 11, color: labelColor)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}s',
                  style: TextStyle(fontSize: 10, color: labelColor)),
            ),
          ),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: types.asMap().entries.map((entry) {
          final times = grouped[entry.value]!;
          final avg = times.isEmpty
              ? 0.0
              : times.reduce((a, b) => a + b) / times.length;
          final colorIdx = activityNames.keys.toList().indexOf(entry.value);
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: avg,
                color: activityColors[colorIdx % activityColors.length],
                width: 22,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Widget reutilizable: barra de filtros de fecha ───
class _DateFilterBar extends StatelessWidget {
  final String selected;
  final DateTimeRange? customRange;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickRange;

  const _DateFilterBar({
    required this.selected,
    required this.customRange,
    required this.onChanged,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('Periodo:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            const SizedBox(width: 8),
            _chip(context, 'Todo', 'todo'),
            _chip(context, 'Semana', 'semana'),
            _chip(context, 'Mes', 'mes'),
            _chip(context, 'Trimestre', 'trimestre'),
            const SizedBox(width: 4),
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 16),
              label: Text(
                selected == 'personalizado' && customRange != null
                    ? '${_fmt(customRange!.start)} – ${_fmt(customRange!.end)}'
                    : 'Personalizado',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: selected == 'personalizado'
                  ? colorScheme.primaryContainer
                  : null,
              onPressed: onPickRange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: colorScheme.primaryContainer,
        onSelected: (_) => onChanged(value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}