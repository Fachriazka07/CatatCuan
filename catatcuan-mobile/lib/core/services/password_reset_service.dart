import 'dart:convert';
import 'dart:io';

import 'package:catatcuan_mobile/core/constants/env.dart';

class PasswordResetService {
  PasswordResetService._();

  static String _cleanErrorMessage(String message) {
    final withoutPrefix = message.replaceFirst('HttpException: ', '').trim();
    final uriSeparatorIndex = withoutPrefix.indexOf(', uri =');

    if (uriSeparatorIndex == -1) {
      return withoutPrefix;
    }

    return withoutPrefix.substring(0, uriSeparatorIndex).trim();
  }

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

  static String? normalizePhoneNumber(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return null;
    }

    if (digitsOnly.startsWith('08')) {
      final normalized = '62${digitsOnly.substring(1)}';
      return normalized.length >= 10 && normalized.length <= 14
          ? normalized
          : null;
    }

    if (!digitsOnly.startsWith('628')) {
      return null;
    }

    return digitsOnly.length >= 10 && digitsOnly.length <= 14
        ? digitsOnly
        : null;
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = _buildUri(path);
    final apiKey = Env.mobileBackendApiKey.trim();

    if (uri == null || apiKey.isEmpty) {
      throw const HttpException(
        'Backend reset password belum dikonfigurasi di file .env mobile.',
      );
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-mobile-api-key', apiKey);
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      Map<String, dynamic> jsonBody = {};
      if (body.isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          jsonBody = decoded;
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            jsonBody['error'] as String? ??
            'Request reset password gagal (${response.statusCode})';
        throw HttpException(message, uri: uri);
      }

      return jsonBody;
    } finally {
      client.close();
    }
  }

  static Future<void> requestOtp(String phoneNumber) async {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);

    if (normalizedPhone == null) {
      throw const HttpException('Nomer HP tidak valid');
    }

    await _post('/api/mobile/auth/request-password-reset', {
      'phoneNumber': normalizedPhone,
    });
  }

  static Future<void> verifyOtpAndResetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);

    if (normalizedPhone == null) {
      throw const HttpException('Nomer HP tidak valid');
    }

    await _post('/api/mobile/auth/verify-password-reset', {
      'phoneNumber': normalizedPhone,
      'code': code.trim(),
      'newPassword': newPassword,
    });
  }

  static String formatError(Object error) {
    return _cleanErrorMessage(error.toString());
  }

  static String maskPhoneNumber(String phoneNumber) {
    final normalized = normalizePhoneNumber(phoneNumber) ?? phoneNumber;

    if (normalized.length <= 6) {
      return normalized;
    }

    final prefix = normalized.substring(0, 4);
    final suffix = normalized.substring(normalized.length - 3);
    final hiddenLength = normalized.length - 7;

    return '$prefix${List.filled(hiddenLength, '*').join()}$suffix';
  }
}
