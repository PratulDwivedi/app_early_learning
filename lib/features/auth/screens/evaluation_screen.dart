import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../common/widgets/custom_dropdown_form_field.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/theme_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/services/navigation_service.dart';
import '../providers/auth_service_provider.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  late String _selectedMode;
  bool _isStarted = false;
  int _currentQuestionIndex = 0;
  String? _recordedAnswerPath;
  String? _selectedOption;
  bool _isRecording = false;

  final List<String> _evaluationModes = [
    '',
    'Letter/Blend Sounds (MCQ)',
    'Letter Recognition (MCQ)',
    'Letter Recognition (Trainer Naming)',
    'Letter/Blend Sounds (Trainer Describing)',
  ];

  // Mock questions for demo (replace with API call)
  final List<Map<String, dynamic>> _mockQuestions = [
    {
      'id': 1,
      'text': 'What is the sound of letter A?',
      'audioUrl': null,
      'options': ['Apple Sound', 'Ball Sound', 'Cat Sound'],
      'optionAudioUrls': [null, null, null],
      'correctAnswer': 0,
    },
    {
      'id': 2,
      'text': 'Recognize the letter B',
      'audioUrl': null,
      'options': ['A', 'B', 'C'],
      'optionAudioUrls': [null, null, null],
      'correctAnswer': 1,
    },
    {
      'id': 3,
      'text': 'What sound does C make?',
      'audioUrl': null,
      'options': ['Cat', 'Dog', 'Ball'],
      'optionAudioUrls': [null, null, null],
      'correctAnswer': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMode = _evaluationModes[0];
  }

  void _startEvaluation() {
    if (_selectedMode.isEmpty) {
      AppSnackbarService.error('Please select an evaluation mode');
      return;
    }
    setState(() => _isStarted = true);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _mockQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _recordedAnswerPath = null;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedOption = null;
        _recordedAnswerPath = null;
      });
    }
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    developer.log(
      'Recording ${_isRecording ? 'started' : 'stopped'}',
      name: 'EvaluationScreen',
    );
    AppSnackbarService.success(
      _isRecording ? 'Recording started...' : 'Recording stopped',
    );
  }

  void _playQuestionAudio() {
    developer.log('Playing question audio', name: 'EvaluationScreen');
    AppSnackbarService.success('Playing question audio...');
  }

  void _playOptionAudio(int optionIndex) {
    developer.log('Playing audio for option $optionIndex', name: 'EvaluationScreen');
    AppSnackbarService.success('Playing option ${optionIndex + 1} audio...');
  }

  void _submitEvaluation() {
    developer.log(
      'Submitting evaluation: mode=$_selectedMode, selectedOption=$_selectedOption, recordedAnswer=$_recordedAnswerPath',
      name: 'EvaluationScreen',
    );
    AppSnackbarService.success('Evaluation submitted successfully!');
    NavigationService.goBack();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);

    // Get current question
    final currentQuestion = _mockQuestions[_currentQuestionIndex];
    final questionText = currentQuestion['text'] as String;
    final options = currentQuestion['options'] as List<String>;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            CommonGradientHeader(
              title: 'Evaluation',
              onRefresh: () {
                ref.invalidate(authInitializerProvider);
              },
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Evaluation Mode Selector
                  if (!_isStarted) ...[
                    Text(
                      'Select Evaluation Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
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
                      child: CustomDropdownFormField<String>(
                        value: _selectedMode,
                        labelText: 'Evaluation Mode',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: colors.hintColor,
                        ),
                        fillColor: colors.inputFillColor,
                        hintColor: colors.hintColor,
                        primaryColor: primaryColor,
                        items: _evaluationModes,
                        itemLabel: (mode) => mode,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMode = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomPrimaryButton(
                      label: 'Start Evaluation',
                      onPressed: _startEvaluation,
                      primaryColor: primaryColor,
                    ),
                  ] else ...[
                    // Question Display
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_mockQuestions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                          // Question Text with Audio Button
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  questionText,
                                  style: TextStyle(
                                    fontSize: 18,
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
                                    Icons.volume_up_rounded,
                                    color: primaryColor,
                                  ),
                                  onPressed: _playQuestionAudio,
                                  tooltip: 'Play question audio',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Options
                          Text(
                            'Select an option:',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.hintColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: List.generate(
                              options.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedOption == options[index]
                                        ? primaryColor.withOpacity(0.2)
                                        : colors.inputFillColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedOption == options[index]
                                          ? primaryColor
                                          : colors.hintColor.withOpacity(0.3),
                                      width: _selectedOption == options[index]
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(
                                              () =>
                                                  _selectedOption = options[index],
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Radio<String>(
                                                  value: options[index],
                                                  groupValue: _selectedOption,
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      setState(() =>
                                                          _selectedOption = value);
                                                    }
                                                  },
                                                  activeColor: primaryColor,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    options[index],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: colors.textColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: primaryColor.withOpacity(0.15),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.volume_up_rounded,
                                              size: 20,
                                              color: primaryColor,
                                            ),
                                            onPressed: () =>
                                                _playOptionAudio(index),
                                            tooltip: 'Play option audio',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recording Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? Colors.red.withOpacity(0.1)
                                  : colors.inputFillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isRecording
                                    ? Colors.red
                                    : colors.hintColor.withOpacity(0.3),
                                width: _isRecording ? 2 : 1,
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
                                      _isRecording
                                          ? 'Recording in progress...'
                                          : _recordedAnswerPath != null
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
                                    color: _isRecording
                                        ? Colors.red
                                        : primaryColor.withOpacity(0.2),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      color: _isRecording ? Colors.white : primaryColor,
                                      size: 28,
                                    ),
                                    onPressed: _toggleRecording,
                                    tooltip: _isRecording
                                        ? 'Stop recording'
                                        : 'Start recording',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomSecondaryButton(
                            label: 'Previous',
                            onPressed: _currentQuestionIndex > 0
                                ? _previousQuestion
                                : null,
                            primaryColor: primaryColor,
                            textColor: colors.textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _currentQuestionIndex < _mockQuestions.length - 1
                              ? CustomPrimaryButton(
                                  label: 'Next',
                                  onPressed: _nextQuestion,
                                  primaryColor: primaryColor,
                                )
                              : CustomPrimaryButton(
                                  label: 'Submit',
                                  onPressed: _submitEvaluation,
                                  primaryColor: primaryColor,
                                ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
