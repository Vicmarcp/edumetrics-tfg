import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ClassAnalyticsScreen extends StatefulWidget {
  final String schoolId;
  const ClassAnalyticsScreen({super.key, required this.schoolId});

  @override
  State<ClassAnalyticsScreen> createState() => _ClassAnalyticsScreenState();
}

class _ClassAnalyticsScreenState extends State<ClassAnalyticsScreen> {
  Map<String, Map<String, dynamic>> _studentData = {};
  List<QueryDocumentSnapshot> _allResultDocs = [];
  Map<String, Map<String, List<bool>>> _activityData = {};
  bool _loading = true;
  String? _selectedClass;
  List<String> _classes = [];
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<List<QueryDocumentSnapshot>> _loadResultsInBatches(
      List<String> studentIds) async {
    final allResults = <QueryDocumentSnapshot>[];
    const batchSize = 30;

    for (var i = 0; i < studentIds.length; i += batchSize) {
      final batch = studentIds.sublist(
        i,
        i + batchSize > studentIds.length ? studentIds.length : i + batchSize,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('schoolId', isEqualTo: widget.schoolId)
          .where('studentId', whereIn: batch)
          .get();

      allResults.addAll(snapshot.docs);
    }

    return allResults;
  }

  Future<void> _loadData() async {
    try {
      final studentsSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: widget.schoolId)
          .where('isActive', isEqualTo: true)
          .get();

      final students = <String, Map<String, dynamic>>{};
      final classes = <String>{};

      for (final doc in studentsSnap.docs) {
        final data = doc.data();
        students[doc.id] = data;
        if (data['className'] != null) {
          classes.add(data['className'] as String);
        }
      }

      List<QueryDocumentSnapshot> resultDocs = [];
      if (students.isNotEmpty) {
        resultDocs = await _loadResultsInBatches(students.keys.toList());
      }

      if (mounted) {
        final sortedClasses = classes.toList()..sort();
        setState(() {
          _studentData = students;
          _allResultDocs = resultDocs;
          _classes = sortedClasses;
          _selectedClass =
          sortedClasses.isNotEmpty ? sortedClasses.first : null;
          _rebuildActivityData();
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

  /// Reconstruye _activityData aplicando el filtro de fecha
  void _rebuildActivityData() {
    final filtered = _applyDateFilter(_allResultDocs);
    final activityData = <String, Map<String, List<bool>>>{};

    for (final doc in filtered) {
      final data = doc.data() as Map<String, dynamic>;
      final studentId = data['studentId'] as String? ?? '';
      final activityType = data['activityType'] as String? ?? '';
      final correct = data['isCorrect'] as bool? ?? false;

      activityData.putIfAbsent(studentId, () => {});
      activityData[studentId]!.putIfAbsent(activityType, () => []);
      activityData[studentId]![activityType]!.add(correct);
    }

    _activityData = activityData;
  }

  List<QueryDocumentSnapshot> _applyDateFilter(
      List<QueryDocumentSnapshot> docs) {
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
          return docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['timestamp'] as Timestamp?;
            if (ts == null) return false;
            final date = ts.toDate();
            return date.isAfter(
                _customRange!.start.subtract(const Duration(days: 1))) &&
                date.isBefore(
                    _customRange!.end.add(const Duration(days: 1)));
          }).toList();
        }
        return docs;
      default:
        return docs;
    }
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['timestamp'] as Timestamp?;
        if (ts == null) return false;
        return ts.toDate().isAfter(start!.subtract(const Duration(seconds: 1)));
      }).toList();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _rebuildActivityData();
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
        _rebuildActivityData();
      });
    }
  }

  List<String> _filteredStudentIds() {
    return _studentData.entries
        .where((e) =>
    _selectedClass == null ||
        e.value['className'] == _selectedClass)
        .map((e) => e.key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
              const Text('Error al cargar datos',
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
                  _loadData();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_studentData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hay alumnos registrados',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
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
          const SizedBox(height: 12),
          // ── Filtro de clase ──
          if (_classes.isNotEmpty)
            Row(
              children: [
                Text('Clase: ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedClass,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Todas')),
                    ..._classes.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _selectedClass = v),
                ),
              ],
            ),
          const SizedBox(height: 24),
          if (_activityData.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('No hay resultados en el periodo seleccionado',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            )
          else ...[
            _buildSectionTitle(context, 'Media de aciertos por alumno'),
            const SizedBox(height: 8),
            SizedBox(
                height: 350,
                child: _buildStudentComparisonChart(context)),
            const SizedBox(height: 32),
            _buildSectionTitle(
                context, 'Dificultad por actividad (media de la clase)'),
            const SizedBox(height: 8),
            SizedBox(
                height: 300,
                child: _buildActivityDifficultyChart(context)),
            const SizedBox(height: 32),
          ],
        ],
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

  Widget _buildStudentComparisonChart(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface;
    final gridColor = Theme.of(context).dividerColor;
    final studentIds = _filteredStudentIds();
    if (studentIds.isEmpty) return const Center(child: Text('Sin datos'));

    final List<_StudentResult> results = [];
    for (final id in studentIds) {
      final name = _studentData[id]?['name'] ?? '?';
      final activities = _activityData[id];
      if (activities == null || activities.isEmpty) continue;

      final allResults = activities.values.expand((e) => e).toList();
      final correct = allResults.where((r) => r).length;
      final percent =
      allResults.isEmpty ? 0.0 : correct * 100 / allResults.length;
      results.add(_StudentResult(name: name, percent: percent));
    }

    results.sort((a, b) => b.percent.compareTo(a.percent));
    if (results.isEmpty) return const Center(child: Text('Sin resultados'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${results[group.x.toInt()].name}\n${rod.toY.round()}%',
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
                if (idx < 0 || idx >= results.length) return const SizedBox();
                final name = results[idx].name;
                final short =
                name.length > 8 ? '${name.substring(0, 8)}.' : name;
                return SideTitleWidget(
                  meta: meta,
                  angle: -0.5,
                  child: Text(short,
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
        barGroups: results.asMap().entries.map((entry) {
          final color = entry.value.percent >= 70
              ? Colors.green
              : entry.value.percent >= 50
              ? Colors.orange
              : Colors.red;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.percent,
                color: color,
                width: 20,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityDifficultyChart(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface;
    final gridColor = Theme.of(context).dividerColor;
    final studentIds = _filteredStudentIds();
    final Map<String, List<bool>> aggregated = {};

    for (final id in studentIds) {
      final activities = _activityData[id];
      if (activities == null) continue;
      for (final entry in activities.entries) {
        aggregated.putIfAbsent(entry.key, () => []).addAll(entry.value);
      }
    }

    final types =
    activityNames.keys.where((k) => aggregated.containsKey(k)).toList();
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
          final results = aggregated[entry.value]!;
          final correct = results.where((r) => r).length;
          final percent =
          results.isEmpty ? 0.0 : correct * 100 / results.length;
          final color = percent >= 70
              ? Colors.green
              : percent >= 50
              ? Colors.orange
              : Colors.red;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: percent,
                color: color,
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

class _StudentResult {
  final String name;
  final double percent;
  _StudentResult({required this.name, required this.percent});
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