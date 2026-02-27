import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/widgets/app_logo_badge.dart';
import '../../common/widgets/theme_selector.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/gradient_background.dart';
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
  bool _hasAcceptedDisclaimer = false;

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

    if (!_hasAcceptedDisclaimer) {
      AppSnackbarService.error('Please accept the disclaimer to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiResponse = await ref.read(
        signUpProvider({
          'userName': _userNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }).future,
      );

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
          apiResponse.message.isEmpty
              ? 'Signup failed. Please try again.'
              : apiResponse.message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbarService.error('Error: $e');
      }
    }
  }

  bool _shouldUseMultiColumnLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    return kIsWeb || isTablet || isLandscape;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final useMultiColumn = _shouldUseMultiColumnLayout(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => NavigationService.goBack(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
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
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 24, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  AppLogoBadge(
                    backgroundColor: colors.cardColor,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final fieldWidth = useMultiColumn
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth;

                              return Wrap(
                                spacing: 16,
                                runSpacing: 20,
                                children: [
                                  SizedBox(
                                    width: fieldWidth,
                                    child: NameTextFormField(
                                      controller: _userNameController,
                                      colors: colors,
                                      primaryColor: primaryColor,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: EmailTextFormField(
                                      controller: _emailController,
                                      colors: colors,
                                      primaryColor: primaryColor,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: PasswordTextFormField(
                                      controller: _passwordController,
                                      colors: colors,
                                      primaryColor: primaryColor,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: PasswordTextFormField(
                                      controller: _confirmPasswordController,
                                      colors: colors,
                                      primaryColor: primaryColor,
                                      labelText: 'Confirm Password',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.inputFillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hasAcceptedDisclaimer
                                    ? primaryColor.withOpacity(0.6)
                                    : colors.hintColor.withOpacity(0.35),
                                width: _hasAcceptedDisclaimer ? 1.6 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disclaimer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Please note that this assessment session will be video and audio recorded for evaluation and verification purposes. By proceeding, you are providing your consent for the recording and use of this data solely for assessment and quality review.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: colors.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _hasAcceptedDisclaimer,
                                      activeColor: primaryColor,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasAcceptedDisclaimer =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          'I have read and agree to this disclaimer.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: colors.textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
