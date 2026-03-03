import 'package:flutter/material.dart';
import '../../../../config/app_config.dart';
import '../../models/theme_colors.dart';

class EvaluationQuestionPanel extends StatelessWidget {
  static const List<Color> optionColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  final ThemeColors colors;
  final Color primaryColor;
  final String questionText;
  final String questionImageUrl;
  final bool isSpeakerEnabled;
  final VoidCallback onSpeakerPressed;
  final bool isConfirmationType;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onOptionSelected;
  final bool isRecording;
  final String? recordedAnswerPath;
  final VoidCallback onToggleRecording;
  final bool isSubmittingAnswer;
  final VoidCallback onConfirmCorrect;
  final VoidCallback onConfirmIncorrect;

  const EvaluationQuestionPanel({
    super.key,
    required this.colors,
    required this.primaryColor,
    required this.questionText,
    required this.questionImageUrl,
    required this.isSpeakerEnabled,
    required this.onSpeakerPressed,
    required this.isConfirmationType,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.isRecording,
    required this.recordedAnswerPath,
    required this.onToggleRecording,
    required this.isSubmittingAnswer,
    required this.onConfirmCorrect,
    required this.onConfirmIncorrect,
  });

  double _optionCardHeight(List<String> values) {
    if (values.isEmpty) return 90;
    final totalChars = values.fold<int>(0, (sum, item) => sum + item.length);
    final avgChars = totalChars / values.length;
    final maxChars = values.fold<int>(0, (max, item) {
      return item.length > max ? item.length : max;
    });

    if (maxChars > 48 || avgChars > 28) return 150;
    if (maxChars > 36 || avgChars > 22) return 132;
    if (maxChars > 24 || avgChars > 16) return 114;
    return 94;
  }

  @override
  Widget build(BuildContext context) {
    final optionCardHeight = _optionCardHeight(options);
    final optionTextMaxLines = optionCardHeight >= 132 ? 3 : 2;
    final hasImage = questionImageUrl.isNotEmpty;
    final resolvedImageUrl = hasImage
        ? (questionImageUrl.startsWith('http')
            ? questionImageUrl
            : '${appConfig.storageUrl}/$questionImageUrl')
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.2),
                ),
                child: IconButton(
                  icon: Icon(
                    isSpeakerEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: primaryColor,
                  ),
                  onPressed: onSpeakerPressed,
                  tooltip: isSpeakerEnabled ? 'Speaker on' : 'Speaker off',
                ),
              ),
            ],
          ),
          if (hasImage) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final imageHeight = (constraints.maxWidth * 0.42).clamp(
                  160.0,
                  280.0,
                );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: Image.network(
                      resolvedImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colors.inputFillColor,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colors.hintColor,
                            size: 30,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colors.inputFillColor,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          if (isConfirmationType) ...[
            if (options.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: options.map((option) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.55),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
            _ConfirmationActions(
              primaryColor: primaryColor,
              colors: colors,
              isSubmittingAnswer: isSubmittingAnswer,
              selectedOption: selectedOption,
              onConfirmCorrect: onConfirmCorrect,
              onConfirmIncorrect: onConfirmIncorrect,
            ),
            const SizedBox(height: 16),
            _buildRecordingCard(),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final gridSpacing = 12.0;
                final cardWidth = (constraints.maxWidth - gridSpacing) / 2;
                return GridView.builder(
                  itemCount: options.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: cardWidth / optionCardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final optionColor = optionColors[index % optionColors.length];
                    final optionValue = options[index];
                    final isSelected = selectedOption == optionValue;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onOptionSelected(optionValue),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color.alphaBlend(
                                  primaryColor.withOpacity(0.25),
                                  optionColor.withOpacity(0.24),
                                )
                              : optionColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : optionColor.withOpacity(0.7),
                            width: isSelected ? 2 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: optionValue,
                              groupValue: selectedOption,
                              onChanged: (value) {
                                if (value != null) onOptionSelected(value);
                              },
                              activeColor: optionColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                optionValue,
                                maxLines: optionTextMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: colors.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRecordingCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecording ? Colors.red.withOpacity(0.1) : colors.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecording ? Colors.red : colors.hintColor.withOpacity(0.3),
          width: isRecording ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Your Answer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRecording
                    ? 'Recording in progress...'
                    : recordedAnswerPath != null
                        ? 'Answer recorded'
                        : 'No recording yet',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.hintColor,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording ? Colors.red : primaryColor.withOpacity(0.2),
            ),
            child: IconButton(
              icon: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: isRecording ? Colors.white : primaryColor,
                size: 28,
              ),
              onPressed: onToggleRecording,
              tooltip: isRecording ? 'Stop recording' : 'Start recording',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationActions extends StatelessWidget {
  final Color primaryColor;
  final ThemeColors colors;
  final bool isSubmittingAnswer;
  final String? selectedOption;
  final VoidCallback onConfirmCorrect;
  final VoidCallback onConfirmIncorrect;

  const _ConfirmationActions({
    required this.primaryColor,
    required this.colors,
    required this.isSubmittingAnswer,
    required this.selectedOption,
    required this.onConfirmCorrect,
    required this.onConfirmIncorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrectSelected = selectedOption == 'Correct';
    final isIncorrectSelected = selectedOption == 'Incorrect';
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isSubmittingAnswer ? null : onConfirmCorrect,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Correct'),
            style: FilledButton.styleFrom(
              backgroundColor: isCorrectSelected
                  ? Colors.green
                  : Colors.green.withOpacity(0.85),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isSubmittingAnswer ? null : onConfirmIncorrect,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('In Correct'),
            style: FilledButton.styleFrom(
              backgroundColor: isIncorrectSelected
                  ? Colors.red
                  : Colors.red.withOpacity(0.85),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
