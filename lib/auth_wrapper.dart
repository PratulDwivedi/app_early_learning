import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/common/screens/edu_home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_service_provider.dart';
//import 'firebase/notification_service.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait for auth initialization to complete
    final authInitAsync = ref.watch(authInitializerProvider);
    final currentUser = ref.watch(authProvider);

    return authInitAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const LoginScreen(),
      data: (user) {
        // User is logged in
        if (currentUser != null) {
          return const EduHomeScreen();
        }

        // User is logged out
        return const LoginScreen();
      },
    );
  }
}

// class AuthWrapper extends ConsumerWidget {
//   final NotificationServices notificationServices;

//   const AuthWrapper({super.key, required this.notificationServices});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final currentUser = ref.watch(authProvider);

//     // User is logged in
//     if (currentUser != null) {
//       notificationServices.firebaseInit(context);
//       return EduHomeScreen();
//     }

//     // User is logged out
//     return const LoginScreen();
//   }
// }
