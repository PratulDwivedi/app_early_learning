import 'package:flutter/material.dart';

class ApiRoutes {
  static const String signIn = 'edu.fn_signin_mobile_delegate';
  static const String profile = 'edu.fn_get_mobile_delegate';
  static const String updatePassword = 'edu.fn_update_delegate_password';
  static const String updateProfilePic = 'edu.fn_update_delegate_profile_pic';
  static const String uploadFile = 'edu/v1/upload-file';
  static const String banners = 'edu.fn_get_mobile_banners';
  static const String feedbackParams = 'edu.fn_get_mobile_feedback_params';

  static const String summaryCount = '';
  static const String fileMetadata = '';
  static const String htmlContent = '';
}

class AppPageRoute {
  static const String webview = 'webview';
  static const String signIn = 'signIn';
  static const String profile = 'profile';
  static const String updatePassword = 'updatePassword';
  static const String helpline = 'helpline';
}

class AppPageIds {
  static const int helpLine = 169;
  static const int fromDgDesk = 141;
  static const int exhibition = 142;
  static const int registration = 143;
  static const int aboutFai = 144;
  static const int seminarTheme = 146;
  static const int conferenceHotel = 147;
  static const int culturalProgramme = 148;
  static const int faqs = 149;
}

Map<String, IconData> pageIcons = {
  // Main Navigation Pages
  'document': Icons.download,
  'resource': Icons.download,
  'registration': Icons.receipt,
  // Bottom Navigation
  'profile': Icons.person,

  // Auth & Account
  'signIn': Icons.login,
  'updatePassword': Icons.lock,

  'helpline': Icons.phone,
  'feedback': Icons.feedback,

  'faq': Icons.help,
  'webview': Icons.web,
};

// Helper function to get page icon
IconData getPageIcon(String pageKey) {
  return pageIcons[pageKey] ?? Icons.info;
}
