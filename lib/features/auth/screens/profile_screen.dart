import '../../common/models/screen_args_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/auth_service_provider.dart';
import '../widgets/profile_picture_upload.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final ScreenArgsModel args;

  const ProfileScreen({required this.args, super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      body: Column(
        children: [
          // Gradient Header
          CommonGradientHeader(
            title: widget.args.name,
            onRefresh: () {
              ref.invalidate(profileProvider);
            },
          ),

          // Profile Content 
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (response) {
                if (!response.isSuccess) {
                  return Center(child: Text(response.message));
                }

                // Assuming response.data contains profile info
                final profileData = response.firstOrNull ?? {};

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Profile Picture Section
                      Center(
                        child: Column(
                          children: [
                            ProfilePictureUpload(
                              currentProfilePic: profileData['profile_pic']
                                  ?.toString(),
                              onProfilePicUpdated: (newProfilePic) {
                                // Refresh the profile data
                                ref.invalidate(profileProvider);
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profileData['full_name']?.toString() ?? 'N/A',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              profileData['e_mail_id']?.toString() ?? 'N/A',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Profile Information Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Profile Information',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
      
                              _buildProfileField(
                                'Full Name',
                                profileData['full_name']?.toString() ?? 'N/A',
                              ),

                              _buildProfileField(
                                'Email',
                                profileData['e_mail_id']?.toString() ?? 'N/A',
                              ),
                              _buildProfileField(
                                'Contact Number',
                                profileData['contact_no']?.toString() ?? 'N/A',
                              ),
                              _buildProfileField(
                                'Biography',
                                profileData['biography']?.toString() ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Change Password Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lock, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Security',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showChangePasswordDialog,
                                  icon: const Icon(Icons.password),
                                  label: const Text('Change Password'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: const Text('Cancel'),
            ),
            _isChangingPassword
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _submitChangePassword(setState),
                    child: const Text('Change Password'),
                  ),
          ],
        ),
      ),
    );
  }

  void _submitChangePassword(StateSetter setState) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isChangingPassword = true);

      try {
        final response = await ref.read(updatePasswordProvider({
          'oldPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }).future);

        if (response.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password changed successfully')),
            );
            Navigator.of(context).pop();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      } finally {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  void _clearForm() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }
}
