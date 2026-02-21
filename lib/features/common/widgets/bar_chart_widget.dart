import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatelessWidget {
  final List<dynamic> data;
  final String title;
  final List<Color>? barColors;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.barColors,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = barColors ??
        [
          Colors.blue,
          Colors.orange,
          Colors.green,
          Colors.purple,
          Colors.red,
          Colors.teal,
          Colors.amber
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(title, style: const TextStyle(fontSize: 14)),
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: [
                for (int i = 0; i < data.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (data[i]['value'] as num).toDouble(),
                        color: colors[i % colors.length],
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 1000,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const Text('0', style: TextStyle(fontSize: 12));
                      } else if (value % 1000 == 0) {
                        return Text('${value ~/ 1000}K',
                            style: const TextStyle(fontSize: 12));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 &&
                          idx < data.length &&
                          (data[idx]['name']?.toString().isNotEmpty ?? false)) {
                        return SizedBox(
                          width: 60,
                          child: Text(
                            data[idx]['name'].toString(),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            for (int i = 0; i < data.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12, height: 12, color: colors[i % colors.length]),
                  const SizedBox(width: 4),
                  Text(data[i]['name'].toString(),
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
