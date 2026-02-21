import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/theme_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/services/navigation_service.dart';
import '../providers/auth_service_provider.dart';
import '../../common/providers/student_provider.dart';

class AddStudentPage extends ConsumerStatefulWidget {
  const AddStudentPage({super.key});

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _gradeController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final student = ref.read(studentFormProvider);

      // Call the API
      final result = await ref.read(
        saveStudentProvider(student).future,
      );

      if (mounted) {
        if (result.isSuccess) {
          AppSnackbarService.success('Student added successfully!');
          ref.read(studentFormProvider.notifier).reset();
          _firstNameController.clear();
          _lastNameController.clear();
          _gradeController.clear();
          _dobController.clear();
          NavigationService.goBack();
        } else {
          AppSnackbarService.error(result.message);
          // Invalidate cache so next attempt gets fresh response
          ref.invalidate(saveStudentProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbarService.error('Error: ${e.toString()}');
        // Invalidate cache so next attempt gets fresh response
        ref.invalidate(saveStudentProvider);
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
              title: 'Student',
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
                    // Title Section
                    Text(
                      'Student Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

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
                          // First Name Field
                          CustomTextFormField(
                            controller: _firstNameController,
                            labelText: 'First Name',
                            hintText: 'Enter first name',
                            prefixIcon: Icons.person_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            onChanged: (value) {
                              ref
                                  .read(studentFormProvider.notifier)
                                  .updateFirstName(value);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required';
                              }
                              if (value.length < 2) {
                                return 'First name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Last Name Field
                          CustomTextFormField(
                            controller: _lastNameController,
                            labelText: 'Last Name',
                            hintText: 'Enter last name',
                            prefixIcon: Icons.person_outline,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.text,
                            onChanged: (value) {
                              ref
                                  .read(studentFormProvider.notifier)
                                  .updateLastName(value);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required';
                              }
                              if (value.length < 2) {
                                return 'Last name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Grade Field
                          CustomTextFormField(
                            controller: _gradeController,
                            labelText: 'Grade',
                            hintText: 'Enter grade (1-3)',
                            prefixIcon: Icons.school_outlined,
                            colors: colors,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final grade = int.tryParse(value);
                              ref
                                  .read(studentFormProvider.notifier)
                                  .updateGrade(grade);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Grade is required';
                              }
                              final grade = int.tryParse(value);
                              if (grade == null || grade < 1 || grade > 3) {
                                return 'Grade must be between 1 and 3';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Date of Birth Field
                          GestureDetector(
                            onTap: _pickDate,
                            child: TextFormField(
                              controller: _dobController,
                              readOnly: true,
                              onTap: _pickDate,
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.inputTextColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                labelStyle: TextStyle(color: colors.hintColor),
                                hintText: 'Select date of birth',
                                hintStyle: TextStyle(color: colors.hintColor),
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: colors.hintColor,
                                ),
                                filled: true,
                                fillColor: colors.inputFillColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Date of birth is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomPrimaryButton(
                      label: _isLoading ? 'Saving Student...' : 'Save Student',
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
