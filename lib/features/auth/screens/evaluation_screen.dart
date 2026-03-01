import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/question_provider.dart';
import '../../common/providers/speech_settings_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/services/navigation_service.dart';
import '../../common/services/speech_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/custom_button.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel? args;

  const EvaluationScreen({super.key, this.args});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  static const List<Color> optionColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  int? _selectedQuestionTypeId;
  bool _isStarted = false;
  bool _isStartingSession = false;
  bool _isSpeakerEnabled = true;
  int _currentQuestionIndex = 0;
  String? _recordedAnswerPath;
  String? _selectedOption;
  bool _isRecording = false;
  bool _isSubmittingAnswer = false;
  int? _sessionId;
  List<Map<String, dynamic>> _sessionQuestions = [];
  DateTime? _questionStartTime;
  final Map<int, String> _selectedAnswersByQuestion = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySessionPayloadFromArgs();
    });
  }

  int get _studentId {
    final raw = widget.args?.data['id'] ?? widget.args?.data['student_id'];
    if (raw is int) return raw;
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed ?? 1;
  }

  List<String> _parseOptions(dynamic rawOptions) {
    if (rawOptions is List) {
      return rawOptions.map((e) => e.toString().trim()).toList();
    }
    if (rawOptions is String) {
      return rawOptions
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  void _applySessionPayloadFromArgs() {
    final rawPayload = widget.args?.data['session_payload'];
    if (rawPayload == null || rawPayload is! Map) return;

    final payload = Map<String, dynamic>.from(rawPayload as Map);
    final questionsRaw = (payload['questions'] as List?) ?? [];
    final questions = questionsRaw
        .map((q) => q is Map ? Map<String, dynamic>.from(q) : null)
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort(
        (a, b) => _toInt(a['sort_order']).compareTo(_toInt(b['sort_order'])),
      );

    if (questions.isEmpty) return;

    setState(() {
      _sessionId = _toInt(payload['session_id']);
      _selectedQuestionTypeId = _toInt(
        payload['question_type_id'] ?? widget.args?.data['question_type_id'],
      );
      _sessionQuestions = questions;
      _selectedAnswersByQuestion.clear();
      _isStarted = true;
      _currentQuestionIndex = 0;
      _selectedOption = null;
      _recordedAnswerPath = null;
      _isRecording = false;
      _questionStartTime = DateTime.now();
    });

    if (_isSpeakerEnabled && mounted) {
      _speakCurrentQuestionFromState();
    }
  }

  Future<void> _startSession(int questionTypeId) async {
    setState(() {
      _isStartingSession = true;
      _selectedQuestionTypeId = questionTypeId;
    });

    try {
      final response = await ref.read(
        startSessionProvider(
          StartSessionArgs(
            studentId: _studentId,
          ),
        ).future,
      );

      if (!response.isSuccess) {
        AppSnackbarService.error(response.message);
        return;
      }

      final sessionData = response.firstOrNull;
      final questionsRaw = (sessionData?['questions'] as List?) ?? [];
      final questions = questionsRaw
          .map((q) => q is Map ? Map<String, dynamic>.from(q) : null)
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) => _toInt(a['sort_order']).compareTo(_toInt(b['sort_order'])));

      if (questions.isEmpty) {
        AppSnackbarService.error('No questions available for selected type.');
        return;
      }

      setState(() {
        _sessionId = _toInt(sessionData?['session_id']);
        _sessionQuestions = questions;
        _selectedAnswersByQuestion.clear();
        _isStarted = true;
        _currentQuestionIndex = 0;
        _selectedOption = null;
        _recordedAnswerPath = null;
        _isRecording = false;
        _questionStartTime = DateTime.now();
      });
      if (_isSpeakerEnabled && mounted) {
        await _speakCurrentQuestionFromState();
      }
    } catch (e) {
      AppSnackbarService.error('Failed to start session: $e');
    } finally {
      if (mounted) {
        setState(() => _isStartingSession = false);
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _sessionQuestions.length - 1) {
      await _submitCurrentAnswerAndProceed();
    }
  }

  Future<void> _previousQuestion() async {
    if (_currentQuestionIndex > 0) {
      final previousQuestionIndex = _currentQuestionIndex - 1;
      final previousQuestion = _sessionQuestions[previousQuestionIndex];
      final previousQuestionId = _toInt(previousQuestion['id']);
      setState(() {
        _currentQuestionIndex = previousQuestionIndex;
        _selectedOption = _selectedAnswersByQuestion[previousQuestionId];
        _recordedAnswerPath = null;
      });
      if (_isSpeakerEnabled && mounted) {
        await _speakCurrentQuestionFromState();
      }
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

  Future<void> _playQuestionAudio(
    Map<String, dynamic>? question,
    String questionText,
  ) async {
    final audioPrompt = (question?['name_audio_prompt'] ?? '')
        .toString()
        .trim();
    final fallbackText = questionText.trim();
    final textToSpeak = audioPrompt.isNotEmpty ? audioPrompt : fallbackText;

    if (textToSpeak.isEmpty) {
      AppSnackbarService.error('No question text available to speak.');
      return;
    }

    developer.log('Playing question audio/TTS', name: 'EvaluationScreen');
    final speechSettings = ref.read(speechSettingsProvider);
    await ref.read(speechServiceProvider).speak(textToSpeak, speechSettings);
  }

  Future<void> _speakCurrentQuestionFromState() async {
    if (!_isStarted || _sessionQuestions.isEmpty) return;
    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= _sessionQuestions.length) {
      return;
    }
    final question = _sessionQuestions[_currentQuestionIndex];
    final questionText = (question['name'] ?? '').toString();
    await _playQuestionAudio(question, questionText);
  }

  Future<void> _submitEvaluation() async {
    await _submitFinalAnswerAndCompleteSession();
  }

  Future<void> _submitCurrentAnswerAndProceed() async {
    if (_isSubmittingAnswer) return;
    setState(() => _isSubmittingAnswer = true);
    final submitted = await _submitCurrentAnswer();
    if (!mounted) return;
    if (!submitted) {
      setState(() => _isSubmittingAnswer = false);
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      final nextQuestion = _sessionQuestions[_currentQuestionIndex];
      final nextQuestionId = _toInt(nextQuestion['id']);
      _selectedOption = _selectedAnswersByQuestion[nextQuestionId];
      _recordedAnswerPath = null;
      _questionStartTime = DateTime.now();
      _isSubmittingAnswer = false;
    });
    if (_isSpeakerEnabled && mounted) {
      await _speakCurrentQuestionFromState();
    }
  }

  Future<void> _submitFinalAnswerAndCompleteSession() async {
    if (_isSubmittingAnswer) return;
    setState(() => _isSubmittingAnswer = true);
    final submitted = await _submitCurrentAnswer();
    if (!mounted) return;
    if (!submitted) {
      setState(() => _isSubmittingAnswer = false);
      return;
    }

    final sessionId = _sessionId;
    if (sessionId == null) {
      AppSnackbarService.error('Session ID missing. Please restart session.');
      setState(() => _isSubmittingAnswer = false);
      return;
    }

    final service = ref.read(eduServiceProvider);
    final completeResponse = await service.completeSession(sessionId, 'COMPLETED');
    if (completeResponse.isSuccess) {
      AppSnackbarService.success('Evaluation submitted successfully!');
      NavigationService.goBack(result: true);
    } else {
      AppSnackbarService.error(completeResponse.message);
      if (mounted) {
        setState(() => _isSubmittingAnswer = false);
      }
    }
  }

  Future<bool> _submitCurrentAnswer() async {
    if (_selectedOption == null || _selectedOption!.trim().isEmpty) {
      AppSnackbarService.error('Please select an answer first.');
      return false;
    }

    final sessionId = _sessionId;
    if (sessionId == null) {
      AppSnackbarService.error('Session ID missing. Please restart session.');
      return false;
    }

    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= _sessionQuestions.length) {
      AppSnackbarService.error('Question context is invalid.');
      return false;
    }

    final question = _sessionQuestions[_currentQuestionIndex];
    final questionId = _toInt(question['id']);
    if (questionId <= 0) {
      AppSnackbarService.error('Question ID missing.');
      return false;
    }

    final studentAnswer = _selectedOption!;
    final timeTakenSec = _questionStartTime == null
        ? 1
        : DateTime.now()
            .difference(_questionStartTime!)
            .inSeconds
            .clamp(1, 36000)
            .toInt();

    developer.log(
      'Submitting answer: sessionId=$sessionId, questionId=$questionId, answer=$studentAnswer, timeTakenSec=$timeTakenSec',
      name: 'EvaluationScreen',
    );

    try {
      final service = ref.read(eduServiceProvider);
      final submitResponse = await service.submitAnswer(
        sessionId,
        questionId,
        studentAnswer,
        timeTakenSec,
      );
      if (!submitResponse.isSuccess) {
        AppSnackbarService.error(submitResponse.message);
        return false;
      }
    } catch (e) {
      AppSnackbarService.error('Failed to submit answer: $e');
      return false;
    }

    return true;
  }

  double _optionCardHeight(List<String> options) {
    if (options.isEmpty) return 90;
    final totalChars = options.fold<int>(0, (sum, item) => sum + item.length);
    final avgChars = totalChars / options.length;
    final maxChars = options.fold<int>(0, (max, item) {
      return item.length > max ? item.length : max;
    });

    if (maxChars > 48 || avgChars > 28) return 150;
    if (maxChars > 36 || avgChars > 22) return 132;
    if (maxChars > 24 || avgChars > 16) return 114;
    return 94;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final questionTypesAsync = ref.watch(getQuestionTypesProvider);

    final currentQuestion =
        _isStarted && _sessionQuestions.isNotEmpty ? _sessionQuestions[_currentQuestionIndex] : null;
    final questionText = (currentQuestion?['name'] ?? '').toString();
    final options = _parseOptions(currentQuestion?['options']);
    final optionCardHeight = _optionCardHeight(options);
    final optionTextMaxLines = optionCardHeight >= 132 ? 3 : 2;

    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'Evaluation',
            onRefresh: () {
              ref.invalidate(authInitializerProvider);
              ref.invalidate(getQuestionTypesProvider);
            },
          ),
          if (_isStarted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
              color: colors.bgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_sessionQuestions.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _sessionQuestions.length,
                    backgroundColor: colors.hintColor.withOpacity(0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isStarted) ...[
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
                      child: questionTypesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text(
                          'Failed to load evaluation modes: $error',
                          style: TextStyle(color: colors.textColor),
                        ),
                        data: (response) {
                          if (!response.isSuccess || response.data.isEmpty) {
                            return Text(
                              response.message,
                              style: TextStyle(color: colors.textColor),
                            );
                          }

                          final modes = List<Map<String, dynamic>>.from(
                            response.data,
                          )..sort(
                              (a, b) => _toInt(a['sort_order']).compareTo(
                                _toInt(b['sort_order']),
                              ),
                            );

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
                                  final modeId = _toInt(mode['id']);
                                  final modeName =
                                      (mode['name'] ?? '').toString();
                                  final isSelected =
                                      _selectedQuestionTypeId == modeId;
                                  return SizedBox(
                                    width: cardWidth,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: _isStartingSession
                                          ? null
                                          : () => _startSession(modeId),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor.withOpacity(0.15)
                                              : colors.inputFillColor,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : colors.hintColor.withOpacity(
                                                    0.3,
                                                  ),
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
                                            if (_isStartingSession &&
                                                isSelected)
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: primaryColor,
                                                ),
                                              )
                                            else
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .radio_button_unchecked,
                                                color: isSelected
                                                    ? primaryColor
                                                    : colors.hintColor,
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
                        },
                      ),
                    ),
                  ] else ...[
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
                                    _isSpeakerEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    color: primaryColor,
                                  ),
                                  onPressed: () async {
                                    final nextValue = !_isSpeakerEnabled;
                                    setState(() => _isSpeakerEnabled = nextValue);
                                    if (nextValue) {
                                      await _speakCurrentQuestionFromState();
                                    } else {
                                      await ref.read(speechServiceProvider).stop();
                                    }
                                  },
                                  tooltip: _isSpeakerEnabled
                                      ? 'Speaker on'
                                      : 'Speaker off',
                                ),
                              ),
                            ],
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final gridSpacing = 12.0;
                              final cardWidth =
                                  (constraints.maxWidth - gridSpacing) / 2;
                              return GridView.builder(
                                itemCount: options.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                  childAspectRatio:
                                      cardWidth / optionCardHeight,
                                ),
                                itemBuilder: (context, index) {
                                  final optionColor =
                                      optionColors[index % optionColors.length];
                                  final optionValue = options[index];
                                  final isSelected =
                                      _selectedOption == optionValue;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      final questionId =
                                          _toInt(currentQuestion?['id']);
                                      setState(() {
                                        _selectedOption = optionValue;
                                        if (questionId > 0) {
                                          _selectedAnswersByQuestion[
                                                  questionId] =
                                              optionValue;
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
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
                                            groupValue: _selectedOption,
                                            onChanged: (value) {
                                              if (value != null) {
                                                final questionId = _toInt(
                                                  currentQuestion?['id'],
                                                );
                                                setState(() {
                                                  _selectedOption = value;
                                                  if (questionId > 0) {
                                                    _selectedAnswersByQuestion[
                                                            questionId] =
                                                        value;
                                                  }
                                                });
                                              }
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
                                                fontSize: 15,
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
                                      color:
                                          _isRecording ? Colors.white : primaryColor,
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
                  ],
                ],
              ),
            ),
          ),
          if (_isStarted)
            SafeArea(
              top: false,
              child: Container(
                color: colors.bgColor,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomSecondaryButton(
                        label: 'Previous',
                        onPressed: _currentQuestionIndex > 0
                            ? () => _previousQuestion()
                            : null,
                        primaryColor: primaryColor,
                        textColor: colors.textColor,
                        height: 56,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _currentQuestionIndex < _sessionQuestions.length - 1
                          ? CustomPrimaryButton(
                              label: 'Next',
                              onPressed: _isSubmittingAnswer ? null : _nextQuestion,
                              primaryColor: primaryColor,
                              isLoading: _isSubmittingAnswer,
                              height: 56,
                            )
                          : CustomPrimaryButton(
                              label: 'Submit',
                              onPressed: _isSubmittingAnswer ? null : _submitEvaluation,
                              primaryColor: primaryColor,
                              isLoading: _isSubmittingAnswer,
                              height: 56,
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
