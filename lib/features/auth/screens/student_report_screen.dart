import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/pie_chart_widget.dart';
import '../../common/widgets/bar_chart_widget.dart';
import '../../common/models/screen_args_model.dart';
import '../providers/theme_provider.dart';
import '../models/theme_colors.dart';
import '../../common/providers/student_provider.dart';

class StudentReportScreen extends ConsumerWidget {
  final ScreenArgsModel? args;

  const StudentReportScreen({super.key, this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentData = args?.data;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonGradientHeader(
              title: "Kid Reports",
              onRefresh: () {
                ref.invalidate(studentSummaryProvider);
              },
            ),
            StudentReportContent(studentData: studentData),
          ],
        ),
      ),
    );
  }
}

class StudentReportContent extends ConsumerWidget {
  final Map<String, dynamic>? studentData;

  const StudentReportContent({super.key, this.studentData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final summaryAsync = ref.watch(studentSummaryProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: summaryAsync.when(
        data: (summaryData) {
          if (summaryData.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 64,
                      color: colors.hintColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Report Data Available',
                      style: TextStyle(fontSize: 16, color: colors.hintColor),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info Card (if student data is passed)
              if (studentData != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.8),
                                primaryColor,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (studentData!['first_name'] ?? 'S')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${studentData!['first_name'] ?? 'Unknown'} ${studentData!['last_name'] ?? ''}',
                                style: TextStyle(
                                  color: colors.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (studentData!['email'] != null)
                                Text(
                                  studentData!['email'],
                                  style: TextStyle(
                                    color: colors.hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 14,
                                    color: colors.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Grade: ${studentData!['grade'] ?? '-'}',
                                    style: TextStyle(
                                      color: colors.hintColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Summary Statistics
              Text(
                'Summary Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryCards(summaryData, colors, primaryColor),
              const SizedBox(height: 24),

              // Pie Chart
              Container(
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PieChartWidget(
                  data: summaryData,
                  title: 'Responses Distribution',
                ),
              ),
              const SizedBox(height: 24),

              // Bar Chart
              Container(
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: BarChartWidget(
                  data: summaryData,
                  title: 'Response Breakdown',
                ),
              ),
              const SizedBox(height: 24),

              // Detailed List
              Text(
                'Detailed Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(summaryData.length, (index) {
                final item = summaryData[index];
                final name = item['name'] ?? 'Unknown';
                final value = item['value'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(
                              0.7 - (index * 0.1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: colors.textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading Report...',
                  style: TextStyle(fontSize: 14, color: colors.hintColor),
                ),
              ],
            ),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(fontSize: 12, color: colors.hintColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    List<dynamic> data,
    ThemeColors colors,
    Color primaryColor,
  ) {
    final totalCount = data.fold<int>(
      0,
      (sum, item) => sum + (item['value'] as int? ?? 0),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            label: 'Total',
            value: totalCount.toString(),
            color: primaryColor,
            colors: colors,
          ),
          const SizedBox(width: 12),
          ...List.generate(
            data.length,
            (index) => _buildStatCard(
              label: (data[index]['name'] as String? ?? 'Unknown')
                  .split(' ')
                  .first,
              value: (data[index]['value'] ?? 0).toString(),
              color: primaryColor.withOpacity(0.7 - (index * 0.1)),
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required ThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: colors.hintColor)),
        ],
      ),
    );
  }
}
