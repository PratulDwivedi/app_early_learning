import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/question_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_dropdown_form_field.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';

class QuestionPage extends ConsumerStatefulWidget {
  final ScreenArgsModel? args;

  const QuestionPage({super.key, this.args});

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameAudioPromptController = TextEditingController();
  final _optionsController = TextEditingController();
  final _optionsAudioPromptController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _hintController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingQuestion = false;
  int? _questionTypeId;

  @override
  void initState() {
    super.initState();
    _loadQuestionIfEditing();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameAudioPromptController.dispose();
    _optionsController.dispose();
    _optionsAudioPromptController.dispose();
    _correctAnswerController.dispose();
    _hintController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  int? get _editingId => _tryParseInt(widget.args?.data['id']);
  bool get _isEditing => _editingId != null;

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Future<void> _loadQuestionIfEditing() async {
    final questionId = _editingId;
    if (questionId == null) return;

    setState(() => _isLoadingQuestion = true);
    try {
      final question = await ref.read(questionByIdProvider(questionId).future);
      if (!mounted || question == null) return;

      setState(() {
        _nameController.text = (question['name'] ?? '').toString();
        _nameAudioPromptController.text =
            (question['name_audio_prompt'] ?? '').toString();
        _optionsController.text = (question['options'] ?? '').toString();
        _optionsAudioPromptController.text =
            (question['options_audio_prompt'] ?? '').toString();
        _correctAnswerController.text =
            (question['correct_answer'] ?? '').toString();
        _hintController.text = (question['hint'] ?? '').toString();
        _imageUrlController.text = (question['image_url'] ?? '').toString();
        _questionTypeId = _tryParseInt(question['question_type_id']);
      });
    } catch (e) {
      AppSnackbarService.error('Failed to load question: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuestion = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questionTypeId == null) {
      AppSnackbarService.error('Please select question type.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        if (_isEditing) 'p_id': _editingId,
        'p_question_type_id': _questionTypeId,
        'p_name': _nameController.text.trim(),
        'p_options': _optionsController.text.trim(),
        'p_correct_answer': _correctAnswerController.text.trim(),
        if (_nameAudioPromptController.text.trim().isNotEmpty)
          'p_name_audio_prompt': _nameAudioPromptController.text.trim(),
        if (_optionsAudioPromptController.text.trim().isNotEmpty)
          'p_options_audio_prompt': _optionsAudioPromptController.text.trim(),
        if (_hintController.text.trim().isNotEmpty)
          'p_hint': _hintController.text.trim(),
        if (_imageUrlController.text.trim().isNotEmpty)
          'p_image_url': _imageUrlController.text.trim(),
      };

      developer.log('saveQuestion payload: $payload', name: 'QuestionForm');

      final service = ref.read(eduServiceProvider);
      final result = await service.saveQuestion(payload);

      if (!mounted) return;

      if (result.isSuccess) {
        AppSnackbarService.success(
          _isEditing
              ? 'Question updated successfully!'
              : 'Question added successfully!',
        );
        NavigationService.goBack(result: true);
      } else {
        AppSnackbarService.error(result.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbarService.error('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final questionTypesAsync = ref.watch(getQuestionTypesProvider);

    final questionTypes = questionTypesAsync.maybeWhen(
      data: (response) {
        if (!response.isSuccess) return <Map<String, dynamic>>[];
        final list = List<Map<String, dynamic>>.from(response.data);
        list.sort(
          (a, b) => (_tryParseInt(a['sort_order']) ?? 0).compareTo(
            _tryParseInt(b['sort_order']) ?? 0,
          ),
        );
        return list;
      },
      orElse: () => <Map<String, dynamic>>[],
    );

    if (!_isEditing && _questionTypeId == null && questionTypes.isNotEmpty) {
      _questionTypeId = _tryParseInt(questionTypes.first['id']);
    }

    final typeIds = questionTypes
        .map((q) => _tryParseInt(q['id']))
        .whereType<int>()
        .toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonGradientHeader(
              title: _isEditing ? 'Edit Question' : 'Question',
              onRefresh: () {
                ref.invalidate(authInitializerProvider);
                ref.invalidate(getQuestionTypesProvider);
                if (_editingId != null) {
                  ref.invalidate(questionByIdProvider(_editingId!));
                  _loadQuestionIfEditing();
                }
              },
            ),
            if (_isLoadingQuestion)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        children: [
                          questionTypesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stack) => Text(
                              'Failed to load question types',
                              style: TextStyle(color: colors.textColor),
                            ),
                            data: (response) {
                              if (!response.isSuccess || typeIds.isEmpty) {
                                return Text(
                                  response.message,
                                  style: TextStyle(color: colors.textColor),
                                );
                              }
                              final selected = typeIds.contains(_questionTypeId)
                                  ? _questionTypeId
                                  : null;
                              return CustomDropdownFormField<int>(
                                isExpanded: true,
                                value: selected,
                                labelText: 'Question Type',
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  color: colors.hintColor,
                                ),
                                fillColor: colors.inputFillColor,
                                hintColor: colors.hintColor,
                                primaryColor: primaryColor,
                                items: typeIds,
                                itemLabel: (id) {
                                  final item = questionTypes.firstWhere(
                                    (q) => _tryParseInt(q['id']) == id,
                                    orElse: () => <String, dynamic>{},
                                  );
                                  return (item['name'] ?? '').toString();
                                },
                                onChanged: (value) {
                                  setState(() => _questionTypeId = value);
                                },
                                validator: (value) {
                                  if (value == null) return 'Required';
                                  return null;
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _nameController,
                            labelText: 'Question',
                            hintText: 'Enter question',
                            prefixIcon: Icons.help_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Question is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _nameAudioPromptController,
                            labelText: 'Question Audio Prompt',
                            hintText: 'e.g. which-starts-with-a.mp3',
                            prefixIcon: Icons.audiotrack_outlined,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _optionsController,
                            labelText: 'Options',
                            hintText: 'e.g. Apple,Ant,Ball,Cat',
                            prefixIcon: Icons.list,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Options are required';
                              }
                              return null;
                            },
                          ),
                          /*
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _optionsAudioPromptController,
                            labelText: 'Options Audio Prompt',
                            hintText: 'e.g. apple-ant-ball-cat.mp3',
                            prefixIcon: Icons.multitrack_audio_outlined,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                          ),
                          */
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _correctAnswerController,
                            labelText: 'Correct Answer',
                            hintText: 'e.g. Apple',
                            prefixIcon: Icons.check_circle_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Correct answer is required';
                              }
                              return null;
                            },
                          ),
                          /*
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _hintController,
                            labelText: 'Hint',
                            hintText: 'Optional hint',
                            prefixIcon: Icons.lightbulb_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _imageUrlController,
                            labelText: 'Image URL',
                            hintText: 'e.g. letter-a.png',
                            prefixIcon: Icons.image_outlined,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                          ),

                          */
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomPrimaryButton(
                      label: _isLoading
                          ? 'Saving...'
                          : (_isEditing ? 'Update' : 'Save'),
                      onPressed:
                          (_isLoading || _isLoadingQuestion) ? null : _submitForm,
                      isLoading: _isLoading,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    CustomSecondaryButton(
                      label: 'Cancel',
                      onPressed: (_isLoading || _isLoadingQuestion)
                          ? null
                          : () => NavigationService.goBack(),
                      primaryColor: primaryColor,
                      textColor: colors.textColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
