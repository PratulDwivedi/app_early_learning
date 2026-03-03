import 'package:flutter/material.dart';
import '../../models/theme_colors.dart';

class EvaluationModeSelector extends StatelessWidget {
  final ThemeColors colors;
  final Color primaryColor;
  final bool isStartingSession;
  final int? selectedQuestionTypeId;
  final List<Map<String, dynamic>> modes;
  final int Function(dynamic value) toInt;
  final ValueChanged<int> onModeTap;

  const EvaluationModeSelector({
    super.key,
    required this.colors,
    required this.primaryColor,
    required this.isStartingSession,
    required this.selectedQuestionTypeId,
    required this.modes,
    required this.toInt,
    required this.onModeTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth > 520;
        final cardWidth = isTwoColumn
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: modes.map((mode) {
            final modeId = toInt(mode['id']);
            final modeName = (mode['name'] ?? '').toString();
            final isSelected = selectedQuestionTypeId == modeId;
            return SizedBox(
              width: cardWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isStartingSession ? null : () => onModeTap(modeId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.15)
                        : colors.inputFillColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : colors.hintColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          modeName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isStartingSession && isSelected)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      else
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? primaryColor : colors.hintColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
