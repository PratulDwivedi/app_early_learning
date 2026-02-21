import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/models/response_message_model.dart';
import '../models/current_user.dart';
import '../services/auth_service.dart';

/// 🔐 Initialize auth on app start - loads user from SharedPreferences
final authInitializerProvider = FutureProvider<CurrentUser?>((ref) async {
  final service = ref.watch(authServiceProvider);
  final user = await service.getCurrentUser();
  // Update auth state when user is loaded
  if (user != null) {
    ref.read(authProvider.notifier).setUser(user);
  }
  return user;
});

/// 🔐 Auth State = CurrentUser (NOT Supabase)
final authProvider = StateNotifierProvider<AuthNotifier, CurrentUser?>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<CurrentUser?> {
  AuthNotifier(this.ref) : super(null);

  final Ref ref;

  /// Update user state after successful login
  void setUser(CurrentUser? user) {
    state = user;
  }

  /// Clear user state on logout
  void clearUser() {
    state = null;
  }
}

final profileProvider = FutureProvider<ResponseMessageModel>((ref) async {
  final service = ref.watch(authServiceProvider);
  return await service.getProfile();
});

/// ✅ Simple boolean auth check (useful for guards)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

// Service providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final updateProfilePictureProvider =
    FutureProvider.family<ResponseMessageModel, String>((
      ref,
      profilePicPath,
    ) async {
      final service = ref.watch(authServiceProvider);
      return await service.updateProfilePicture(profilePicPath);
    });

final updatePasswordProvider =
    FutureProvider.family<ResponseMessageModel, Map<String, String>>((
      ref,
      passwords,
    ) async {
      final service = ref.watch(authServiceProvider);
      return await service.updatePassword(
        passwords['oldPassword']!,
        passwords['newPassword']!,
        passwords['confirmPassword']!,
      );
    });

final signUpProvider =
    FutureProvider.family<ResponseMessageModel, Map<String, String>>((
      ref,
      payload,
    ) async {
      final service = ref.watch(authServiceProvider);
      return await service.signUp(
        userName: payload['userName']!,
        email: payload['email']!,
        password: payload['password']!,
      );
    });

final submitFeedbackProvider =
    FutureProvider.family<ResponseMessageModel, String>((ref, feedback) async {
      final service = ref.watch(authServiceProvider);
      return await service.submitFeedback(feedback);
    });
