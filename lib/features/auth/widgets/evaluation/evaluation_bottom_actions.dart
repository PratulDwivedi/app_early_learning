import 'package:flutter/material.dart';
import '../../../common/widgets/custom_button.dart';
import '../../models/theme_colors.dart';

class EvaluationBottomActions extends StatelessWidget {
  final ThemeColors colors;
  final Color primaryColor;
  final bool isSubmittingAnswer;
  final int currentQuestionIndex;
  final int totalQuestions;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const EvaluationBottomActions({
    super.key,
    required this.colors,
    required this.primaryColor,
    required this.isSubmittingAnswer,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: colors.bgColor,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: CustomSecondaryButton(
                label: 'Previous',
                onPressed: onPrevious,
                primaryColor: primaryColor,
                textColor: colors.textColor,
                height: 56,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: currentQuestionIndex < totalQuestions - 1
                  ? CustomPrimaryButton(
                      label: 'Next',
                      onPressed: isSubmittingAnswer ? null : onNext,
                      primaryColor: primaryColor,
                      isLoading: isSubmittingAnswer,
                      height: 56,
                    )
                  : CustomPrimaryButton(
                      label: 'Submit',
                      onPressed: isSubmittingAnswer ? null : onSubmit,
                      primaryColor: primaryColor,
                      isLoading: isSubmittingAnswer,
                      height: 56,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
