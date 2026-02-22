import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentAnalyticsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  List<QueryDocumentSnapshot> _results = [];
  bool _loading = true;

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
    final snapshot = await FirebaseFirestore.instance
        .collection('results')
        .where('studentId', isEqualTo: widget.studentId)
        .orderBy('timestamp', descending: false)
        .get();

    if (mounted) {
      setState(() {
        _results = snapshot.docs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas: ${widget.studentName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(
        child: Text(
          'Este alumno aún no tiene resultados',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Porcentaje de aciertos por actividad'),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: _buildAccuracyChart(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Evolución temporal del rendimiento'),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: _buildEvolutionChart(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Tiempo medio por pregunta (segundos)'),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: _buildTimeChart(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalCorrect = _results.where((r) {
      final data = r.data() as Map<String, dynamic>;
      return data['isCorrect'] == true;
    }).length;
    final totalPercent =
    _results.isEmpty ? 0 : (totalCorrect * 100 / _results.length).round();
    final avgTime = _results.isEmpty
        ? 0
        : (_results.fold<int>(0, (total, r) {
      final data = r.data() as Map<String, dynamic>;
      return total + ((data['timeSeconds'] as num?)?.toInt() ?? 0);
    }) /
        _results.length)
        .round();

    final activities = _results
        .map((r) => (r.data() as Map<String, dynamic>)['activityType'])
        .toSet()
        .length;

    return Row(
      children: [
        _summaryCard('Total respuestas', '${_results.length}', Colors.blue),
        const SizedBox(width: 12),
        _summaryCard('% Aciertos', '$totalPercent%', Colors.green),
        const SizedBox(width: 12),
        _summaryCard('Tiempo medio', '${avgTime}s', Colors.orange),
        const SizedBox(width: 12),
        _summaryCard('Actividades', '$activities', Colors.purple),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // GRÁFICA 1: Barras de % aciertos por actividad
  Widget _buildAccuracyChart() {
    final Map<String, List<bool>> grouped = {};
    for (final result in _results) {
      final data = result.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? 'unknown';
      final correct = data['isCorrect'] as bool? ?? false;
      grouped.putIfAbsent(type, () => []).add(correct);
    }

    final types = activityNames.keys.where((k) => grouped.containsKey(k)).toList();
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
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
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
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: types.asMap().entries.map((entry) {
          final results = grouped[entry.value]!;
          final correct = results.where((r) => r).length;
          final percent = results.isEmpty ? 0.0 : correct * 100 / results.length;
          final colorIdx = activityNames.keys.toList().indexOf(entry.value);

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: percent,
                color: activityColors[colorIdx % activityColors.length],
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // GRÁFICA 2: Línea temporal de evolución
  Widget _buildEvolutionChart() {
    // Agrupar resultados por sesión (misma actividad + mismo timestamp cercano)
    // Simplificación: agrupar en bloques de 10 respuestas consecutivas
    if (_results.length < 10) {
      return const Center(
        child: Text('Se necesitan al menos 10 respuestas para ver la evolución'),
      );
    }

    final List<FlSpot> spots = [];
    const blockSize = 10;
    final blocks = _results.length ~/ blockSize;

    for (int i = 0; i < blocks; i++) {
      final block = _results.sublist(i * blockSize, (i + 1) * blockSize);
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
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Sesión ${spot.x.toInt() + 1}: ${spot.y.round()}%',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Sesiones', style: TextStyle(fontSize: 12)),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
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
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  // GRÁFICA 3: Tiempo medio por actividad
  Widget _buildTimeChart() {
    final Map<String, List<int>> grouped = {};
    for (final result in _results) {
      final data = result.data() as Map<String, dynamic>;
      final type = data['activityType'] as String? ?? 'unknown';
      final time = (data['timeSeconds'] as num?)?.toInt() ?? 0;
      grouped.putIfAbsent(type, () => []).add(time);
    }

    final types = activityNames.keys.where((k) => grouped.containsKey(k)).toList();
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
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
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
                return Text('${value.toInt()}s', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: types.asMap().entries.map((entry) {
          final times = grouped[entry.value]!;
          final avg = times.isEmpty ? 0.0 : times.reduce((a, b) => a + b) / times.length;
          final colorIdx = activityNames.keys.toList().indexOf(entry.value);

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: avg,
                color: activityColors[colorIdx % activityColors.length].withValues(alpha: 0.7),
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}