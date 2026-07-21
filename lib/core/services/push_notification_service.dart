import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class PushNotificationService {
  final AuthRepository _authRepository;

  PushNotificationService(this._authRepository);

  Future<void> initializeAndRegister() async {
    try {
      // 1. Initialize Firebase only on Mobile platforms (Android/iOS)
      if (kIsWeb) {
        // Skip web push notification registration if options are not configured
        if (kDebugMode) {
          print('PushNotificationService: Web platform detected. Skipping initialization without FirebaseOptions.');
        }
        return;
      }
      await Firebase.initializeApp();

      // 2. Request User Permission
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted notification permission');
        }

        // 3. Get FCM Token
        String? token;
        if (kIsWeb) {
          // NOTE: Web push requires a VAPID key from your Firebase Console (Cloud Messaging -> Web configuration)
          token = await messaging.getToken(
            vapidKey: 'YOUR_VAPID_PUBLIC_KEY',
          );
        } else {
          token = await messaging.getToken();
        }

        if (token != null) {
          final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
          await _authRepository.uploadDeviceToken(token, platform);
          if (kDebugMode) {
            print('FCM Token successfully uploaded: $token');
          }
        }

        // 4. Listen to foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Foreground notification received in app: ${message.notification?.title} - ${message.notification?.body}');
          }
        });
      } else {
        if (kDebugMode) {
          print('User declined notification permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('PushNotificationService initialization failed: $e');
      }
    }
  }
}
