import '../../../config/app_config.dart';
import '../../common/models/auth_response_model.dart';
import '../../common/models/response_message_model.dart';
import '../models/current_user.dart';
import 'supabase_auth_service.dart';

abstract class AuthService {
  // Factory method to get the concrete implementation
  static AuthService get instance {
    if (appConfig.serviceType == ServiceType.supabase) {
      return SupabaseAuthService();
    } else {
      return SupabaseAuthService();
      //return CustomAuthService();
    }
  }

  Future<CurrentUser?> getCurrentUser();

  Future<AuthResponseModel> signIn({
    required String email,
    required String password,
  });

  Future<ResponseMessageModel> getProfile();

  Future<void> signOut();

  Future<ResponseMessageModel> updatePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  );

  Future<ResponseMessageModel> updateProfilePicture(String profilePicPath);

  Future<ResponseMessageModel> submitFeedback(String feedback);
}
