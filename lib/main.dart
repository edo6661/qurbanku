import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:qurban_ku/services/news_service.dart';
import 'package:qurban_ku/services/savings_service.dart';
import 'package:qurban_ku/services/storage_service.dart';
import 'app.dart';
import 'services/auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  String? token = await messaging.getToken();
  print("FCM Token: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  final authService = AuthService();
  final storageService = StorageService();
  final savingsService = SavingsService();
  final newsService = NewsService(storageService: storageService);

  runApp(
    App(
      authService: authService,
      storageService: storageService,
      savingsService: savingsService,
      newsService: newsService,
    ),
  );
}
