import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_constants.dart';
import '../../common/models/auth_response_model.dart';
import '../../common/models/response_message_model.dart';
import '../../common/services/supabase_api_helper.dart';
import '../models/current_user.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  @override
  Future<CurrentUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("user_profile");

    if (jsonString == null) return null;

    return CurrentUser.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<AuthResponseModel> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await SupabaseApiHelper.signin(ApiRoutes.signIn, {
      'email': email,
      'password': password,
    });

    // If signin succeeded, fetch profile and cache it locally
    if (authResponse.accessToken!.isNotEmpty) {
      try {
        final profileResponse = await SupabaseApiHelper.post(
          ApiRoutes.profile,
          null,
        );

        if (profileResponse.isSuccess) {
          final prefs = await SharedPreferences.getInstance();
          // store the first item from response.data as user_profile
          if (profileResponse.data.isNotEmpty) {
            await prefs.setString(
              'user_profile',
              json.encode(profileResponse.data[0]),
            );
          }
        }
      } catch (e) {
        // ignore profile caching errors for now; signin still succeeded
      }
    }

    return authResponse;
  }

  @override
  Future<ResponseMessageModel> getProfile() {
    return SupabaseApiHelper.safeApiCall(() async {
      final response = await SupabaseApiHelper.post(ApiRoutes.profile, null);

      if (response.isSuccess) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode(response.data[0]));
      }
      return response;
    });
  }

  @override
  Future<void> signOut() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
      await prefs.remove('access_token');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ResponseMessageModel> updatePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) {
    return SupabaseApiHelper.safeApiCall(() async {
      return await SupabaseApiHelper.post(ApiRoutes.updatePassword, {
        'p_old_password': oldPassword,
        'p_new_password': newPassword,
        'p_confirm_password': confirmPassword,
      });
    });
  }

  @override
  Future<ResponseMessageModel> updateProfilePicture(String profilePicPath) {
    return SupabaseApiHelper.safeApiCall(() async {
      return await SupabaseApiHelper.post(ApiRoutes.updateProfilePic, {
        'p_profile_pic': profilePicPath,
      });
    });
  }

  @override
  Future<ResponseMessageModel> submitFeedback(String feedback) {
    return SupabaseApiHelper.safeApiCall(() async {
      return await SupabaseApiHelper.post(ApiRoutes.feedback, {
        'p_feedback': feedback,
      });
    });
  }
}
