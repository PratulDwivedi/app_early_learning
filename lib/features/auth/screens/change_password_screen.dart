import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/models/screen_args_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/services/navigation_service.dart';
import '../../common/models/response_message_model.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel args;

  const ChangePasswordScreen({required this.args, super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isJwtExpiredResponse(ResponseMessageModel response) {
    final message = response.message.toLowerCase();
    return response.statusCode == 401 ||
        message.contains('jwt expired') ||
        message.contains('token expired') ||
        message.contains('invalid jwt');
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final changePasswordState = ref.watch(changePasswordControllerProvider);
    final isChangingPassword = changePasswordState.isLoading;

    ref.listen<AsyncValue<ResponseMessageModel?>>(
      changePasswordControllerProvider,
      (previous, next) async {
        next.whenOrNull(
          data: (response) async {
            if (response == null || !mounted) return;

            if (response.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
              _clearForm();
            } else if (_isJwtExpiredResponse(response)) {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (!mounted) return;
              NavigationService.clearAndNavigate('login');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${response.message}')),
              );
            }
          },
          error: (error, stackTrace) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
          },
        );
      },
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            CommonGradientHeader(
              title: widget.args.name,
              onRefresh: () {
                // Refresh user data by invalidating auth initializer
                ref.invalidate(authInitializerProvider);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    PasswordTextFormField(
                      controller: _oldPasswordController,
                      labelText: 'Current Password',

                      colors: colors,
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: 16),

                    PasswordTextFormField(
                      controller: _newPasswordController,
                      labelText: 'New Password',
                      colors: colors,
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: 16),

                    PasswordTextFormField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm New Password',
                      colors: colors,
                      primaryColor: primaryColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomPrimaryButton(
                      label: 'Change Password',
                      onPressed: _submitChangePassword,
                      isLoading: isChangingPassword,
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: 16),

                    CustomSecondaryButton(
                      label: 'Clear',
                      onPressed: _clearForm,
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

  void _submitChangePassword() {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(changePasswordControllerProvider.notifier)
          .submit(
            oldPassword: _oldPasswordController.text.trim(),
            newPassword: _newPasswordController.text.trim(),
            confirmPassword: _confirmPasswordController.text.trim(),
          );
    }
  }

  void _clearForm() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }
}
