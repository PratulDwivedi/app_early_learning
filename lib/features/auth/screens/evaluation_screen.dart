import 'dart:async';
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
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/evaluation/evaluation_bottom_actions.dart';
import '../widgets/evaluation/evaluation_mode_selector.dart';
import '../widgets/evaluation/evaluation_progress_header.dart';
import '../widgets/evaluation/evaluation_question_panel.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel? args;

  const EvaluationScreen({super.key, this.args});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  bool _isStarted = false;
  bool _isStartingSession = false;
  bool _isSpeakerEnabled = true;
  bool _isSubmittingAnswer = false;
  bool _isRecording = false;
  bool _isTimingOut = false;

  int? _selectedQuestionTypeId;
  int? _sessionId;
  int _currentQuestionIndex = 0;
  int _totalDurationMinutes = 0;
  int _remainingSeconds = 0;

  String? _recordedAnswerPath;
  String? _selectedOption;
  DateTime? _questionStartTime;

  Timer? _sessionTimer;

  List<Map<String, dynamic>> _sessionQuestions = [];
  final Map<int, String> _selectedAnswersByQuestion = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySessionPayloadFromArgs();
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  int get _studentId {
    final raw = widget.args?.data['id'] ?? widget.args?.data['student_id'];
    if (raw is int) return raw;
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed ?? 1;
  }

  bool get _isCurrentQuestionConfirmationType {
    if (!_isStarted || _sessionQuestions.isEmpty) return false;
    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= _sessionQuestions.length) {
      return false;
    }
    return _toBool(_sessionQuestions[_currentQuestionIndex]['is_confirmation_type']);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
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

  List<Map<String, dynamic>> _extractSortedQuestions(Map<String, dynamic>? sessionData) {
    final questionsRaw = (sessionData?['questions'] as List?) ?? [];
    return questionsRaw
        .map((q) => q is Map ? Map<String, dynamic>.from(q) : null)
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) {
        final orderCompare = _toInt(a['sort_order']).compareTo(_toInt(b['sort_order']));
        if (orderCompare != 0) return orderCompare;
        return _toInt(a['id']).compareTo(_toInt(b['id']));
      });
  }

  void _startSessionTimer(int durationMinutes) {
    _sessionTimer?.cancel();
    final safeMinutes = durationMinutes > 0 ? durationMinutes : 30;
    setState(() {
      _totalDurationMinutes = safeMinutes;
      _remainingSeconds = safeMinutes * 60;
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        await _handleTimeout();
        return;
      }

      setState(() => _remainingSeconds = _remainingSeconds - 1);
    });
  }

  Future<void> _handleTimeout() async {
    if (_isTimingOut) return;
    _isTimingOut = true;

    final sessionId = _sessionId;
    if (sessionId != null) {
      try {
        final service = ref.read(eduServiceProvider);
        final response = await service.completeSession(sessionId, 'ABANDONED');
        if (!response.isSuccess) {
          AppSnackbarService.error(response.message);
        }
      } catch (e) {
        AppSnackbarService.error('Failed to close timed-out session: $e');
      }
    }

    if (mounted) {
      await ref.read(speechServiceProvider).stop();
      AppSnackbarService.error('Session timed out and was marked as abandoned.');
      NavigationService.goBack(result: true);
    }
  }

  void _applySessionPayloadFromArgs() {
    final rawPayload = widget.args?.data['session_payload'];
    if (rawPayload == null || rawPayload is! Map) return;

    final payload = Map<String, dynamic>.from(rawPayload);
    final questions = _extractSortedQuestions(payload);
    if (questions.isEmpty) return;

    final totalDurationMinutes = _toInt(payload['total_duration_minutes']);

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

    _startSessionTimer(totalDurationMinutes);

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
      final questions = _extractSortedQuestions(sessionData);
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

      _startSessionTimer(_toInt(sessionData?['total_duration_minutes']));

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

  Future<void> _previousQuestion() async {
    if (_currentQuestionIndex <= 0) return;

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
    final audioPrompt = (question?['name_audio_prompt'] ?? '').toString().trim();
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

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _sessionQuestions.length - 1) {
      await _submitCurrentAnswerAndProceed();
    }
  }

  Future<void> _submitEvaluation() async {
    await _submitFinalAnswerAndCompleteSession();
  }

  void _selectOptionForCurrentQuestion(String selectedValue) {
    final currentQuestion = _sessionQuestions[_currentQuestionIndex];
    final questionId = _toInt(currentQuestion['id']);

    setState(() {
      _selectedOption = selectedValue;
      if (questionId > 0) {
        _selectedAnswersByQuestion[questionId] = selectedValue;
      }
    });
  }

  Future<void> _onConfirmAnswer(bool isCorrect) async {
    final selectedValue = isCorrect ? 'Correct' : 'Incorrect';
    _selectOptionForCurrentQuestion(selectedValue);

    if (_currentQuestionIndex < _sessionQuestions.length - 1) {
      await _submitCurrentAnswerAndProceed();
    } else {
      await _submitFinalAnswerAndCompleteSession();
    }
  }

  Future<void> _onMcqOptionSelected(String selectedValue) async {
    _selectOptionForCurrentQuestion(selectedValue);

    if (_currentQuestionIndex < _sessionQuestions.length - 1) {
      await _submitCurrentAnswerAndProceed();
    } else {
      await _submitFinalAnswerAndCompleteSession();
    }
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
      _sessionTimer?.cancel();
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

    final rawAnswer = _selectedOption?.trim();
    final studentAnswer =
        rawAnswer == null || rawAnswer.isEmpty ? null : rawAnswer;
    final timeTakenSec = _questionStartTime == null
        ? 1
        : DateTime.now().difference(_questionStartTime!).inSeconds.clamp(1, 36000).toInt();

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

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final questionTypesAsync = ref.watch(getQuestionTypesProvider);

    final currentQuestion =
        _isStarted && _sessionQuestions.isNotEmpty ? _sessionQuestions[_currentQuestionIndex] : null;
    final questionText = (currentQuestion?['name'] ?? '').toString();
    final options = _parseOptions(currentQuestion?['options']);

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
            EvaluationProgressHeader(
              colors: colors,
              primaryColor: primaryColor,
              currentQuestionIndex: _currentQuestionIndex,
              totalQuestions: _sessionQuestions.length,
              totalDurationMinutes: _totalDurationMinutes,
              remainingSeconds: _remainingSeconds,
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
                        loading: () => const Center(child: CircularProgressIndicator()),
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

                          final modes = List<Map<String, dynamic>>.from(response.data)
                            ..sort((a, b) => _toInt(a['sort_order']).compareTo(_toInt(b['sort_order'])));

                          return EvaluationModeSelector(
                            colors: colors,
                            primaryColor: primaryColor,
                            isStartingSession: _isStartingSession,
                            selectedQuestionTypeId: _selectedQuestionTypeId,
                            modes: modes,
                            toInt: _toInt,
                            onModeTap: _startSession,
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    EvaluationQuestionPanel(
                      colors: colors,
                      primaryColor: primaryColor,
                      questionText: questionText,
                      isSpeakerEnabled: _isSpeakerEnabled,
                      onSpeakerPressed: () async {
                        final nextValue = !_isSpeakerEnabled;
                        setState(() => _isSpeakerEnabled = nextValue);
                        if (nextValue) {
                          await _speakCurrentQuestionFromState();
                        } else {
                          await ref.read(speechServiceProvider).stop();
                        }
                      },
                      isConfirmationType: _isCurrentQuestionConfirmationType,
                      options: options,
                      selectedOption: _selectedOption,
                      onOptionSelected: (value) => _onMcqOptionSelected(value),
                      isRecording: _isRecording,
                      recordedAnswerPath: _recordedAnswerPath,
                      onToggleRecording: _toggleRecording,
                      isSubmittingAnswer: _isSubmittingAnswer,
                      onConfirmCorrect: () => _onConfirmAnswer(true),
                      onConfirmIncorrect: () => _onConfirmAnswer(false),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isStarted)
            EvaluationBottomActions(
              colors: colors,
              primaryColor: primaryColor,
              isSubmittingAnswer: _isSubmittingAnswer,
              currentQuestionIndex: _currentQuestionIndex,
              totalQuestions: _sessionQuestions.length,
              onPrevious: _currentQuestionIndex > 0 ? () => _previousQuestion() : null,
              onNext: _nextQuestion,
              onSubmit: _submitEvaluation,
            ),
        ],
      ),
    );
  }
}
