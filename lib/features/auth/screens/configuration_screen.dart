import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/providers/student_provider.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/custom_button.dart';
import '../providers/theme_provider.dart';

class ConfigurationScreen extends ConsumerStatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  ConsumerState<ConfigurationScreen> createState() =>
      _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _totalQuestionsController =
      TextEditingController();
  final TextEditingController _totalDurationController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  @override
  void dispose() {
    _totalQuestionsController.dispose();
    _totalDurationController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ref.read(eduServiceProvider).getConfig();
      if (!mounted) return;

      if (!response.isSuccess) {
        AppSnackbarService.error(response.message);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final config = response.firstOrNull ?? <String, dynamic>{};
      final data = config['data'] is Map
          ? Map<String, dynamic>.from(config['data'] as Map)
          : <String, dynamic>{};

      _totalQuestionsController.text = _toInt(
        data['total_questions'],
      ).toString();
      _totalDurationController.text = _toInt(
        data['total_duration_minutes'],
      ).toString();

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      AppSnackbarService.error('Failed to load config: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final totalQuestions = int.parse(_totalQuestionsController.text.trim());
    final totalDuration = int.parse(_totalDurationController.text.trim());

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ref
          .read(eduServiceProvider)
          .saveConfig(
            totalQuestions: totalQuestions,
            totalDurationMinutes: totalDuration,
          );

      if (!mounted) return;

      if (response.isSuccess) {
        AppSnackbarService.success('Configuration saved successfully.');
      } else {
        AppSnackbarService.error(response.message);
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbarService.error('Failed to save config: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final primaryColor = ref.watch(primaryColorProvider);

    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(title: 'Configuration', onRefresh: _loadConfig),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _totalQuestionsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Total Questions',
                                filled: true,
                                fillColor: colors.inputFillColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Total questions is required';
                                }
                                final number = int.tryParse(text);
                                if (number == null || number <= 0) {
                                  return 'Enter a valid number > 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _totalDurationController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Total Duration Minutes',
                                filled: true,
                                fillColor: colors.inputFillColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Total duration is required';
                                }
                                final number = int.tryParse(text);
                                if (number == null || number <= 0) {
                                  return 'Enter a valid number > 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: CustomPrimaryButton(
                                label: 'Save Configuration',
                                onPressed: _isSaving ? null : _saveConfig,
                                primaryColor: primaryColor,
                                isLoading: _isSaving,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
