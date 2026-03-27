import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsProfileData {
  const SettingsProfileData({
    required this.userId,
    required this.warungId,
    required this.ownerName,
    required this.warungName,
    required this.phoneNumber,
    required this.address,
  });

  final String userId;
  final String warungId;
  final String ownerName;
  final String warungName;
  final String phoneNumber;
  final String address;
}

class SettingsProfileService {
  SettingsProfileService._();

  static final supabase = Supabase.instance.client;

  static Future<SettingsProfileData> getProfileData() async {
    final userId = await SessionService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Session user tidak ditemukan');
    }

    final warungRow = await supabase
        .from('WARUNG')
        .select('id, nama_pemilik, nama_warung, alamat')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (warungRow == null) {
      throw Exception('Data warung tidak ditemukan');
    }

    final userRow = await supabase
        .from('USERS')
        .select('phone_number')
        .eq('id', userId)
        .maybeSingle();

    return SettingsProfileData(
      userId: userId,
      warungId: warungRow['id'] as String,
      ownerName: (warungRow['nama_pemilik'] as String?)?.trim() ?? '',
      warungName: (warungRow['nama_warung'] as String?)?.trim() ?? '',
      phoneNumber: (userRow?['phone_number'] as String?)?.trim() ??
          (await SessionService.getUserPhone())?.trim() ??
          '',
      address: (warungRow['alamat'] as String?)?.trim() ?? '',
    );
  }

  static Future<void> updateOwnerProfile({
    required String userId,
    required String warungId,
    required String ownerName,
    required String phoneNumber,
  }) async {
    await supabase
        .from('WARUNG')
        .update({'nama_pemilik': ownerName})
        .eq('id', warungId);

    await supabase
        .from('USERS')
        .update({'phone_number': phoneNumber})
        .eq('id', userId);

    await SessionService.saveSession(userId, phoneNumber);

    final cache = DataCacheService.instance;
    cache.userName = ownerName;
  }

  static Future<void> updateWarungData({
    required String warungId,
    required String warungName,
    required String address,
  }) async {
    await supabase.from('WARUNG').update({
      'nama_warung': warungName,
      'alamat': address,
    }).eq('id', warungId);

    final cache = DataCacheService.instance;
    cache.warungName = warungName;
  }
}
