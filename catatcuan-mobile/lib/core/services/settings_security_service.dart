import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsSecurityService {
  SettingsSecurityService._();

  static final supabase = Supabase.instance.client;

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = await SessionService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Session user tidak ditemukan');
    }

    await supabase.rpc(
      'change_mobile_user_password',
      params: {
        'p_user_id': userId,
        'p_current_password': currentPassword,
        'p_new_password': newPassword,
      },
    );
  }
}
