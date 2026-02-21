import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  final List<dynamic> data;
  final String title;
  final List<Color>? pieColors;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.pieColors,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = pieColors ??
        [
          Colors.pink,
          Colors.red,
          Colors.blue,
          Colors.orange,
          Colors.green,
          Colors.purple,
          Colors.teal,
          Colors.amber
        ];
    final total =
        data.fold<num>(0, (sum, item) => sum + (item['value'] as num));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(title, style: const TextStyle(fontSize: 14)),
        ),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: [
                for (int i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: (data[i]['value'] as num).toDouble(),
                    color: colors[i % colors.length],
                    title: '',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 32,
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
                  Text(
                    '${data[i]['name']} (${((data[i]['value'] as num) / total * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
