import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/widgets/theme_selector.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/custom_button.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';
import '../../common/services/navigation_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      AppSnackbarService.error('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiResponse = await ref.read(signUpProvider({
        'userName': _userNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      }).future);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (apiResponse.isSuccess) {
        AppSnackbarService.success(
          apiResponse.message.isEmpty
              ? 'Account created successfully! Please login.'
              : apiResponse.message,
        );
        // Navigate back to login screen
        NavigationService.clearAndNavigate('login');
      } else {
        AppSnackbarService.error(
          apiResponse.message.isEmpty ? 'Signup failed. Please try again.' : apiResponse.message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbarService.error('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => const ThemeSelector(),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: colors.bgColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      size: 60,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Title
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join Early Learning Today',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.hintColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Signup Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username Field
                          NameTextFormField(
                            controller: _userNameController,
                            colors: colors,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          EmailTextFormField(
                            controller: _emailController,
                            colors: colors,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          PasswordTextFormField(
                            controller: _passwordController,
                            colors: colors,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password Field
                          PasswordTextFormField(
                            controller: _confirmPasswordController,
                            colors: colors,
                            primaryColor: primaryColor,
                            labelText: 'Confirm Password',
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          CustomPrimaryButton(
                            label: 'Sign Up',
                            onPressed: _handleSignup,
                            isLoading: _isLoading,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(color: colors.hintColor),
                              ),
                              TextButton(
                                onPressed: () {
                                  NavigationService.goBack();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
