import 'package:flutter/material.dart';
import '../../models/theme_colors.dart';

class EvaluationProgressHeader extends StatelessWidget {
  final ThemeColors colors;
  final Color primaryColor;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int totalDurationMinutes;
  final int remainingSeconds;

  const EvaluationProgressHeader({
    super.key,
    required this.colors,
    required this.primaryColor,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.totalDurationMinutes,
    required this.remainingSeconds,
  });

  String get _remainingLabel {
    final safeSeconds = remainingSeconds < 0 ? 0 : remainingSeconds;
    final mins = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      color: colors.bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${currentQuestionIndex + 1} of $totalQuestions',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.hintColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Duration: $totalDurationMinutes min',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Time left: $_remainingLabel',
                style: TextStyle(
                  fontSize: 13,
                  color: remainingSeconds <= 60 ? Colors.red : colors.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalQuestions == 0
                ? 0
                : (currentQuestionIndex + 1) / totalQuestions,
            backgroundColor: colors.hintColor.withOpacity(0.25),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ],
      ),
    );
  }
}
