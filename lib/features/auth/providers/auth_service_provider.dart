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

  /// Refresh user data from server and update local state
  Future<void> refreshUserFromServer() async {
    try {
      final service = ref.watch(authServiceProvider);
      final profileResponse = await service.getProfile();
      
      if (profileResponse.isSuccess) {
        // Parse the fresh user data and update state
        final user = CurrentUser.fromJson(profileResponse.data[0]);
        setUser(user);
      }
    } catch (e) {
      // Log error but don't throw - keep current user state
      print('Error refreshing user from server: $e');
    }
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

final changePasswordControllerProvider = StateNotifierProvider.autoDispose<
  ChangePasswordController,
  AsyncValue<ResponseMessageModel?>
>((ref) {
  return ChangePasswordController(ref);
});

class ChangePasswordController
    extends StateNotifier<AsyncValue<ResponseMessageModel?>> {
  ChangePasswordController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<ResponseMessageModel> submit({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(authServiceProvider);
      final response = await service.updatePassword(
        oldPassword,
        newPassword,
        confirmPassword,
      );
      state = AsyncValue.data(response);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ResponseMessageModel.error(message: e.toString());
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

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
