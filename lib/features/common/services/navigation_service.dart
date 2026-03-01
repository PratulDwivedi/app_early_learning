import 'package:app_early_learning/features/auth/screens/feedback_screen.dart';
import 'package:app_early_learning/features/auth/screens/student_screen.dart';
import 'package:app_early_learning/features/auth/screens/students_list_screen.dart';
import 'package:app_early_learning/features/auth/screens/question_screen.dart';
import 'package:app_early_learning/features/auth/screens/question_list_screen.dart';
import 'package:app_early_learning/features/auth/screens/evaluation_screen.dart';
import 'package:app_early_learning/features/auth/screens/student_sessions_screen.dart';
import 'package:app_early_learning/features/auth/screens/speech_settings_screen.dart';
import 'package:app_early_learning/features/auth/screens/guardians_screen.dart';
import 'package:app_early_learning/features/auth/screens/student_report_screen.dart';
import 'package:app_early_learning/features/auth/screens/upload_questions_screen.dart';
import 'package:app_early_learning/features/auth/screens/offline_sync_screen.dart';
import 'package:app_early_learning/features/auth/screens/configuration_screen.dart';
import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';
import '../screens/edu_home_screen.dart';
import '../models/screen_args_model.dart';
import '../../auth/screens/change_password_screen.dart';
import '../screens/web_view_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final Map<String, WidgetBuilder> _routes = {
    'login': (context) => const LoginScreen(),
    'signup': (context) => const SignupScreen(),
    'home': (context) => const EduHomeScreen(),
  };

  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    if (_routes.containsKey(routeName)) {
      return navigatorKey.currentState?.pushNamed(
        routeName,
        arguments: arguments,
      );
    } else {
      ScreenArgsModel args;
      if (arguments is ScreenArgsModel) {
        args = arguments;
      } else if (arguments is Map<String, dynamic>) {
        args = ScreenArgsModel(
          routeName: routeName,
          name: routeName,
          data: arguments,
        );
      } else {
        args = ScreenArgsModel(routeName: routeName, name: routeName);
      }

      switch (routeName) {
        case AppPageRoute.webview:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => WebViewScreen(args: args)),
          );
        case AppPageRoute.changePassword:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(args: args),
            ),
          );
        case AppPageRoute.feedback:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => FeedbackScreen(args: args)),
          );
        case AppPageRoute.addstudent:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => StudentPage(args: args),
            ),
          );
        case AppPageRoute.addquestion:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => QuestionPage(args: args),
            ),
          );
        case AppPageRoute.questions:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const QuestionListScreen(),
            ),
          );
        case AppPageRoute.evaluation:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => EvaluationScreen(args: args),
            ),
          );
        case AppPageRoute.studentSessions:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => StudentSessionsScreen(args: args),
            ),
          );
        case AppPageRoute.speechSettings:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const SpeechSettingsScreen(),
            ),
          );
        case AppPageRoute.students:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const StudentsListScreen(),
            ),
          );
        case AppPageRoute.guardians:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const GuardiansScreen(),
            ),
          );
        case AppPageRoute.reports:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => StudentReportScreen(args: arguments is ScreenArgsModel ? arguments : null),
            ),
          );
        case AppPageRoute.uploadQuestions:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => UploadQuestionsScreen(args: args),
            ),
          );
        case AppPageRoute.configuration:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const ConfigurationScreen(),
            ),
          );
        case AppPageRoute.offlineSync:
          return navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OfflineSyncScreen(args: args),
            ),
          );
        default:
          return null;
      }
    }
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    // If route is not in map, it might be a dynamic route handled by navigateTo
    return null;
  }

  static Future<dynamic>? clearAndNavigate(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static Future<dynamic>? navigate(String routeName, {Object? arguments}) {
    return navigateTo(routeName, arguments: arguments);
  }

  static void goBack({Object? result}) {
    navigatorKey.currentState?.pop(result);
  }
}
