import 'dart:async';
import 'dart:io';

import 'package:catatcuan_mobile/core/services/notification_backend_service.dart';
import 'package:catatcuan_mobile/core/services/settings_preferences_service.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore repeated initialization attempts in the background isolate.
  }

  debugPrint('Background message received: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _firebaseReady = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase init skipped: $error');
      _firebaseReady = false;
      return;
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('Push permission request failed: $error');
    }

    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (String token) async {
        final userId = await SessionService.getUserId();
        if (userId == null || userId.isEmpty) {
          return;
        }

        try {
          await _registerTokenForUser(
            userId: userId,
            token: token,
          );
        } catch (error) {
          debugPrint('Push token refresh sync failed: $error');
        }
      },
    );
  }

  Future<void> syncForUser(String userId) async {
    if (!_firebaseReady) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is empty, skip sync');
        return;
      }

      debugPrint('FCM token acquired for user $userId');
      await _registerTokenForUser(userId: userId, token: token);
      await syncPreferencesForCurrentUser();
    } catch (error) {
      debugPrint('Push syncForUser failed: $error');
    }
  }

  Future<void> syncPreferencesForCurrentUser() async {
    final userId = await SessionService.getUserId();
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final settings =
          await SettingsPreferencesService.getNotificationSettings();

      await NotificationBackendService.syncNotificationPreferences(
        userId: userId,
        dueDateReminder:
            settings[SettingsPreferencesService.dueDateReminderKey] ?? true,
        lowStockAlert:
            settings[SettingsPreferencesService.lowStockAlertKey] ?? true,
        dailyReminder:
            settings[SettingsPreferencesService.dailyReminderKey] ?? false,
      );
    } catch (error) {
      debugPrint('Push preference sync failed: $error');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_firebaseReady) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await NotificationBackendService.unregisterDeviceToken(token);
    } catch (error) {
      debugPrint('Push unregisterCurrentDevice failed: $error');
    }
  }

  Future<void> _registerTokenForUser({
    required String userId,
    required String token,
  }) async {
    await NotificationBackendService.registerDeviceToken(
      userId: userId,
      token: token,
      platform: _resolvePlatform(),
    );
  }

  String _resolvePlatform() {
    if (kIsWeb) {
      return 'web';
    }

    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return 'unknown';
  }
}
