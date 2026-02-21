import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/custom_dropdown_form_field.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/theme_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/services/navigation_service.dart';
import '../providers/auth_service_provider.dart';
import '../../common/providers/question_provider.dart';
import '../../common/models/question_model.dart';

class QuestionPage extends ConsumerStatefulWidget {
  const QuestionPage({super.key});

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  final _optionsCsvController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _displayLetterController = TextEditingController();
  final _hintController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _sortOrderController = TextEditingController();
  late String _questionMode;
  bool _isLoading = false;

  final List<String> _questionModes = [
    '',
    'Letter/Blend Sounds (MCQ)',
    'Letter Recognition (MCQ)',
    'Letter Recognition (Trainer Naming)',
    'Letter/Blend Sounds (Trainer Describing)',
  ];

  @override
  void initState() {
    super.initState();
    _questionMode = _questionModes[0];
    _difficultyController.text = '1';
    _sortOrderController.text = '0';
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _optionsCsvController.dispose();
    _correctAnswerController.dispose();
    _displayLetterController.dispose();
    _hintController.dispose();
    _difficultyController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build Question directly from form controllers
      final difficulty = int.tryParse(_difficultyController.text);
      final sortOrder = int.tryParse(_sortOrderController.text);

      final question = Question(
        questionText: _questionTextController.text.trim(),
        questionMode: _questionMode,
        optionsCsv: _optionsCsvController.text.trim().isEmpty
            ? null
            : _optionsCsvController.text.trim(),
        correctAnswer: _correctAnswerController.text.trim().isEmpty
            ? null
            : _correctAnswerController.text.trim(),
        displayLetter: _displayLetterController.text.trim().isEmpty
            ? null
            : _displayLetterController.text.trim(),
        hint: _hintController.text.trim().isEmpty
            ? null
            : _hintController.text.trim(),
        difficulty: difficulty ?? 1,
        sortOrder: sortOrder ?? 0,
      );

      developer.log(
        'Submitting Question: questionText=${question.questionText}, mode=${question.questionMode}, difficulty=${question.difficulty}',
        name: 'AddQuestionForm',
      );

      // Call the API directly via service
      final service = ref.read(eduServiceProvider);
      final result = await service.saveQuestion(question);

      if (mounted) {
        if (result.isSuccess) {
          AppSnackbarService.success('Question added successfully!');
          ref.read(questionFormProvider.notifier).reset();
          _questionTextController.clear();
          _optionsCsvController.clear();
          _correctAnswerController.clear();
          _displayLetterController.clear();
          _hintController.clear();
          _difficultyController.text = '1';
          _sortOrderController.text = '0';
          setState(() => _questionMode = _questionModes[0]);
          NavigationService.goBack();
        } else {
          AppSnackbarService.error(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbarService.error('Error: ${e.toString()}');
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

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            CommonGradientHeader(
              title: 'Question',
              onRefresh: () {
                ref.invalidate(authInitializerProvider);
              },
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Fields Container
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
                          // Question Mode Dropdown
                          CustomDropdownFormField<String>(
                            isExpanded: true,
                            value: _questionMode,
                            labelText: 'Question Mode',
                            prefixIcon: Icon(
                              Icons.category_outlined,
                              color: colors.hintColor,
                            ),
                            fillColor: colors.inputFillColor,
                            hintColor: colors.hintColor,
                            primaryColor: primaryColor,
                            items: _questionModes,
                            itemLabel: (mode) => mode,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _questionMode = value);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          // Question Text Field
                          CustomTextFormField(
                            controller: _questionTextController,
                            labelText: 'Question Text',
                            hintText: 'Enter question text',
                            prefixIcon: Icons.help_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Question text is required';
                              }
                              if (value.length < 5) {
                                return 'Question must be at least 5 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Options (CSV) Field
                          CustomTextFormField(
                            controller: _optionsCsvController,
                            labelText: 'Options (comma-separated)',
                            hintText: 'e.g., Option A, Option B, Option C',
                            prefixIcon: Icons.list,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),

                          // Correct Answer Field
                          CustomTextFormField(
                            controller: _correctAnswerController,
                            labelText: 'Correct Answer',
                            hintText: 'Enter correct answer',
                            prefixIcon: Icons.check_circle_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 20),

                          // Display Letter Field
                          CustomTextFormField(
                            controller: _displayLetterController,
                            labelText: 'Display Letter',
                            hintText: 'e.g., A, B, C',
                            prefixIcon: Icons.text_fields,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 20),

                          // Hint Field
                          /*
                          CustomTextFormField(
                            controller: _hintController,
                            labelText: 'Hint',
                            hintText: 'Optional hint for the question',
                            prefixIcon: Icons.lightbulb_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),

                          // Difficulty Field
                          CustomTextFormField(
                            controller: _difficultyController,
                            labelText: 'Difficulty (1-5)',
                            hintText: 'Enter difficulty level',
                            prefixIcon: Icons.grade,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final difficulty = int.tryParse(value);
                                if (difficulty == null ||
                                    difficulty < 1 ||
                                    difficulty > 5) {
                                  return 'Difficulty must be between 1 and 5';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Sort Order Field
                          CustomTextFormField(
                            controller: _sortOrderController,
                            labelText: 'Sort Order',
                            hintText: 'Enter sort order',
                            prefixIcon: Icons.sort,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                int.tryParse(value);
                              }
                              return null;
                            },
                          ),
                           */
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomPrimaryButton(
                      label: _isLoading ? 'Saving...' : 'Save',
                      onPressed: _isLoading ? null : _submitForm,
                      isLoading: _isLoading,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    CustomSecondaryButton(
                      label: 'Cancel',
                      onPressed: _isLoading
                          ? null
                          : () {
                              NavigationService.goBack();
                            },
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
