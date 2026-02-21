import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/services/app_snackbar_service.dart';
import '../../common/widgets/theme_selector.dart';
import '../../common/widgets/custom_text_form_field.dart';
import '../../common/widgets/custom_button.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';
import '../../common/services/navigation_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // _emailController.text = "admin@earlylearning.com";
    // _passwordController.text = "Admin@123";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    final apiResponse = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    // ✅ Safe null-aware check — no force unwrap
    if (!(apiResponse.accessToken?.isNotEmpty == true)) {
      AppSnackbarService.error(
        apiResponse.msg?.isNotEmpty == true
            ? apiResponse.msg!
            : 'Login failed: Invalid email or password',
      );
      return;
    }

    // ✅ Only reaches here on successful login
    await ref.read(authProvider.notifier).refreshUserFromServer();
    NavigationService.clearAndNavigate('home');
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
                    'Welcome Early Learning',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 16, color: colors.hintColor),
                  ),
                  const SizedBox(height: 40),

                  // Login Form Card
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
                          const SizedBox(height: 16),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle forgot password
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: colors.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Text(
                                      'Forgot Password',
                                      style: TextStyle(color: colors.textColor),
                                    ),
                                    content: Text(
                                      'A password reset link will be sent to your email address.',
                                      style: TextStyle(color: colors.textColor),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: primaryColor),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Reset link sent to your email',
                                              ),
                                              backgroundColor: primaryColor,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Send'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          CustomPrimaryButton(
                            label: 'Login',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(color: colors.hintColor),
                              ),
                              TextButton(
                                onPressed: () {
                                  NavigationService.navigate('signup');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                ),
                                child: const Text(
                                  'Sign Up',
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
