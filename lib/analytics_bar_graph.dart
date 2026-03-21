import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsBarGraphSundayService extends StatelessWidget {
  final List<double> firstValues;
  final List<double> secondValues;
  final List<String> labels;

  const AnalyticsBarGraphSundayService({
    super.key,
    required this.firstValues,
    required this.secondValues,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];

    for (var i = 0; i < labels.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: firstValues[i],
              color: Colors.deepPurple,
              width: 8,
            ),
            BarChartRodData(
              toY: secondValues[i],
              color: Colors.green,
              width: 8,
            ),
          ],
          barsSpace: 6,
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: ([
                  ...firstValues,
                  ...secondValues,
                ].reduce((a, b) => a > b ? a : b)) *
            1.1,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(labels[index]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 10),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 10),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(enabled: true),
        groupsSpace: 20,
      ),
    );
  }
}