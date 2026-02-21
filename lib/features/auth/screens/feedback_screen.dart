import '../../common/models/screen_args_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/auth_service_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel args;

  const FeedbackScreen({required this.args, super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _feedbackController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSubmittingFeedback = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    TextFormField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        labelText: 'Feedback',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your feedback';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    _isSubmittingFeedback
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitFeedback,
                            child: const Text('Submit Feedback'),
                          ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _clearForm,
                      child: const Text('Clear'),
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

  void _submitFeedback() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmittingFeedback = true);

      try {
        final response = await ref.read(
          submitFeedbackProvider(_feedbackController.text).future,
        );

        if (response.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback submitted successfully')),
            );
            _clearForm();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response.message}')),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        }
      } finally {
        if (mounted) setState(() => _isSubmittingFeedback = false);
      }
    }
  }

  void _clearForm() {
    _feedbackController.clear();
  }
}
