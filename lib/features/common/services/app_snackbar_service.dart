import 'package:flutter/material.dart';

class AppSnackbarService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void error(String message) {
    _show(message, Icons.error, Colors.red);
  }

  static void success(String message) {
    _show(message, Icons.check_circle, Colors.green);
  }

  static void _show(String message, IconData icon, Color backgroundColor) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
