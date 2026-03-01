import 'package:flutter/material.dart';

class ApiRoutes {
  static const String signIn = 'auth/v1/token?grant_type=password';
  static const String signUp = 'edu-guardian-signup';
  static const String profile = 'public.fn_get_profile';
  static const String addstudent = 'edu.fn_save_student';
  static const String getStudents = 'edu.fn_get_students';
  static const String addquestion = 'edu.fn_save_question';
  static const String savequestions = 'edu.fn_save_questions';
  static const String getQuestions = 'edu.fn_get_questions';
  static const String getQuestionTypes = 'edu.fn_get_question_types';
  static const String getConfig = 'edu.fn_get_config';
  static const String saveConfig = 'edu.fn_save_config';
  static const String getStudentSessions = 'edu.fn_get_student_sessions';
  static const String startSession = 'edu.fn_start_session';
  static const String submitAnswer = 'edu.fn_submit_answer';
  static const String completeSession = 'edu.fn_complete_session';
  static const String updateProfilePic = 'edu.fn_update_profile_pic';
  static const String uploadFile = 'edu/v1/upload-file';
  static const String summaryCount = 'edu.fn_get_student_summary';
  static const String fileMetadata = '';
  static const String htmlContent = '';
  static const String feedback = 'edu.fn_save_feedback';
  static const String getGuardians = 'edu.fn_get_gurdians';
}

class AppPageRoute {
  static const String webview = 'webview';
  static const String signIn = 'signIn';
  static const String profile = 'profile';
  static const String addstudent = 'addstudent';
  static const String students = 'students';
  static const String addquestion = 'addquestion';
  static const String questions = 'questions';
  static const String evaluation = 'evaluation';
  static const String studentSessions = 'studentSessions';
  static const String speechSettings = 'speechSettings';
  static const String changePassword = 'changePassword';
  static const String helpline = 'helpline';
  static const String feedback = 'feedback';
  static const String guardians = 'guardians';
  static const String reports = 'reports';
  static const String uploadQuestions = 'uploadQuestions';
  static const String configuration = 'configuration';
  static const String offlineSync = 'offlineSync';
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
