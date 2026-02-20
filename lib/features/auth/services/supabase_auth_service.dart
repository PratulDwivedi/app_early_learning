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
    return await SupabaseApiHelper.signin(ApiRoutes.signIn, {
      'email': email,
      'password': password,
    });
  }

  @override
  Future<ResponseMessageModel> getProfile() {
    return SupabaseApiHelper.safeApiCall(() async {
      return await SupabaseApiHelper.post(ApiRoutes.profile, null);
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
}
