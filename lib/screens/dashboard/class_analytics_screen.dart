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
  Map<String, Map<String, List<bool>>> _activityData = {};
  bool _loading = true;
  String? _selectedClass;
  List<String> _classes = [];
  String? _errorMessage;

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

      final activityData = <String, Map<String, List<bool>>>{};

      if (students.isNotEmpty) {
        final resultsDocs =
        await _loadResultsInBatches(students.keys.toList());

        for (final doc in resultsDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentId = data['studentId'] as String? ?? '';
          final activityType = data['activityType'] as String? ?? '';
          final correct = data['isCorrect'] as bool? ?? false;

          activityData.putIfAbsent(studentId, () => {});
          activityData[studentId]!.putIfAbsent(activityType, () => []);
          activityData[studentId]![activityType]!.add(correct);
        }
      }

      if (mounted) {
        final sortedClasses = classes.toList()..sort();
        setState(() {
          _studentData = students;
          _activityData = activityData;
          _classes = sortedClasses;
          _selectedClass =
          sortedClasses.isNotEmpty ? sortedClasses.first : null;
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
            const SizedBox(height: 8),
            Text('Añade alumnos desde la sección de gestión',
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
          if (_classes.isNotEmpty)
            Row(
              children: [
                const Text('Clase: ',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          _buildSectionTitle('Media de aciertos por alumno'),
          const SizedBox(height: 8),
          SizedBox(height: 350, child: _buildStudentComparisonChart()),
          const SizedBox(height: 32),
          _buildSectionTitle('Dificultad por actividad (media de la clase)'),
          const SizedBox(height: 8),
          SizedBox(height: 300, child: _buildActivityDifficultyChart()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildStudentComparisonChart() {
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
                  child: Text(short, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  Widget _buildActivityDifficultyChart() {
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
                  child: Text(
                    activityNames[types[idx]] ?? types[idx],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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