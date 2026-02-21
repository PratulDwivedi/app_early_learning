import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'auth_wrapper.dart';
import 'config/app_config.dart';
import 'features/auth/providers/theme_provider.dart';
import 'features/common/services/app_snackbar_service.dart';
import 'features/common/services/navigation_service.dart';
//import 'firebase/firebase_options.dart';
//import 'firebase/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /*
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request notification permissions and set up FCM
  final notificationServices = NotificationServices();
  notificationServices.requestNotificationPermission();
  notificationServices.isTokenRefresh();

  runApp(
    ProviderScope(child: MyApp(notificationServices: notificationServices)),
  );
 */
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  // final NotificationServices notificationServices;
  // const MyApp({super.key, required this.notificationServices});

  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDarkMode = themeState.isDarkMode;
    final primaryColor = ref.watch(primaryColorProvider);

    return MaterialApp(
      title: appConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: NavigationService.onGenerateRoute,
      home: AuthWrapper(),
      // home: AuthWrapper(notificationServices: notificationServices),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppSnackbarService.scaffoldMessengerKey,
    );
  }
}
