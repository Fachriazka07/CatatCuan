import 'dart:convert';
import 'dart:io';

import 'package:catatcuan_mobile/core/constants/env.dart';

class NotificationBackendService {
  NotificationBackendService._();

  static Uri? _buildUri(String path) {
    final baseUrl = Env.mobileBackendBaseUrl.trim();
    if (baseUrl.isEmpty) {
      return null;
    }

    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse('$normalizedBaseUrl$path');
  }

  static Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final uri = _buildUri('/api/mobile/device-token');
    final apiKey = Env.mobileBackendApiKey.trim();

    if (uri == null || apiKey.isEmpty) {
      return;
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-mobile-api-key', apiKey);
      request.add(
        utf8.encode(
          jsonEncode({
            'userId': userId,
            'token': token,
            'platform': platform,
          }),
        ),
      );

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException(
          'Gagal register device token (${response.statusCode}): $body',
          uri: uri,
        );
      }
    } finally {
      client.close();
    }
  }

  static Future<void> unregisterDeviceToken(String token) async {
    final uri = _buildUri('/api/mobile/device-token');
    final apiKey = Env.mobileBackendApiKey.trim();

    if (uri == null || apiKey.isEmpty) {
      return;
    }

    final client = HttpClient();

    try {
      final request = await client.deleteUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-mobile-api-key', apiKey);
      request.add(
        utf8.encode(
          jsonEncode({
            'token': token,
          }),
        ),
      );

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException(
          'Gagal unregister device token (${response.statusCode}): $body',
          uri: uri,
        );
      }
    } finally {
      client.close();
    }
  }

  static Future<void> syncNotificationPreferences({
    required String userId,
    required bool dueDateReminder,
    required bool lowStockAlert,
    required bool dailyReminder,
    bool pushEnabled = true,
    bool smsEnabled = true,
  }) async {
    final uri = _buildUri('/api/mobile/notification-preferences');
    final apiKey = Env.mobileBackendApiKey.trim();

    if (uri == null || apiKey.isEmpty) {
      return;
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-mobile-api-key', apiKey);
      request.add(
        utf8.encode(
          jsonEncode({
            'userId': userId,
            'pushEnabled': pushEnabled,
            'smsEnabled': smsEnabled,
            'dueDateReminder': dueDateReminder,
            'lowStockAlert': lowStockAlert,
            'dailyReminder': dailyReminder,
          }),
        ),
      );

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException(
          'Gagal sync preferensi notifikasi (${response.statusCode}): $body',
          uri: uri,
        );
      }
    } finally {
      client.close();
    }
  }
}
