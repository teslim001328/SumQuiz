import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ActivityChart extends StatelessWidget {
  final List<MapEntry<DateTime, int>> activityData;
  final String title;

  const ActivityChart({
    super.key,
    required this.activityData,
    this.title = 'Activity',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Prepare data for the chart
    final chartData = _prepareChartData(activityData);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData
                          .asMap()
                          .map((index, value) => MapEntry(index.toDouble(),
                              FlSpot(index.toDouble(), value)))
                          .values
                          .toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            final date = DateTime.now().subtract(
                                Duration(days: chartData.length - index - 1));
                            return Text(
                              DateFormat('E').format(date),
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _prepareChartData(List<MapEntry<DateTime, int>> rawData) {
    // Create a map for the last 7 days
    final dailyActivity = <DateTime, int>{};
    final now = DateTime.now();

    // Initialize with zeros for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyActivity[date] = 0;
    }

    // Fill in the actual data
    for (var entry in rawData) {
      final dateKey = DateTime(entry.key.year, entry.key.month, entry.key.day);
      if (dailyActivity.containsKey(dateKey)) {
        dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + entry.value;
      }
    }

    // Convert to list of values
    return dailyActivity.values.map((value) => value.toDouble()).toList();
  }
}
