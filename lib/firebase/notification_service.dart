import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../features/common/models/screen_args_model.dart';
import '../features/common/services/navigation_service.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification Granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Notification granted provisional');
    } else {
      debugPrint('Notification user denied');
    }
  }

  void initLocalNotifications(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitializationSettings = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
        handleMessage(context, message);
      },
    );
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(message.notification?.title.toString() ?? '');
      debugPrint(message.notification?.body.toString() ?? '');
      initLocalNotifications(context, message);
      showNotification(message);
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
          Random.secure().nextInt(100000).toString(),
          "High Importance Notification ",
          importance: Importance.max,
        );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          androidNotificationChannel.id.toString(),
          androidNotificationChannel.name.toString(),
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );

    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title.toString() ?? '',
        message.notification?.body.toString() ?? '',
        notificationDetails,
      );
    });
  }

  Future<String> getDeviceFcmToken() async {
    String? token = await messaging.getToken();
    return token ?? '';
  }

  Future<void> handleMessage(
    BuildContext context,
    RemoteMessage message,
  ) async {
    try {
      ScreenArgsModel screenArgsModel = ScreenArgsModel(
        routeName: message.data["routeName"].toString(),
        name: message.data["name"].toString(),
        data: message.data,
      );

      NavigationService.navigateTo(
        screenArgsModel.routeName,
        arguments: screenArgsModel,
      );
    } catch (e, stackTrace) {
      debugPrint("Error in handleMessage: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  void isTokenRefresh() {
    messaging.onTokenRefresh.listen((event) {
      debugPrint('refresh token: $event');
    });
  }
}
