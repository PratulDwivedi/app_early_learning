import 'package:app_early_learning/features/auth/screens/feedback_screen.dart';
import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../../auth/screens/login_screen.dart';
import '../screens/edu_home_screen.dart';
import '../models/screen_args_model.dart';
import '../../auth/screens/change_password_screen.dart';
import '../screens/web_view_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final Map<String, WidgetBuilder> _routes = {
    'login': (context) => const LoginScreen(),
    'home': (context) => const EduHomeScreen(),
  };

  static void navigateTo(String routeName, {Object? arguments}) {
    if (_routes.containsKey(routeName)) {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
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
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => WebViewScreen(args: args)),
          );
          break;
        case AppPageRoute.changePassword:
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(args: args),
            ),
          );
          break;
        case AppPageRoute.feedback:
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => FeedbackScreen(args: args)),
          );
          break;
        default:
          // Handle unknown routes or do nothing
          break;
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
}
