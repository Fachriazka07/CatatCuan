import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsMasterDataService {
  SettingsMasterDataService._();

  static final _supabase = Supabase.instance.client;
  static final _cache = DataCacheService.instance;

  static Future<List<Map<String, dynamic>>> getProductCategories() async {
    await _cache.refreshCategories();
    return List<Map<String, dynamic>>.from(_cache.categories)
      ..sort((a, b) {
        final orderA = (a['sort_order'] as num?)?.toInt() ?? 0;
        final orderB = (b['sort_order'] as num?)?.toInt() ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return (a['nama_kategori'] as String? ?? '')
            .compareTo(b['nama_kategori'] as String? ?? '');
      });
  }

  static Future<void> addProductCategory(String name) async {
    final warungId = _cache.warungId;
    if (warungId == null) throw Exception('Warung tidak ditemukan');

    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Nama kategori harus diisi');

    await _supabase.from('KATEGORI_PRODUK').insert({
      'warung_id': warungId,
      'nama_kategori': trimmed,
      'icon': 'Lainya.png',
      'sort_order': _cache.categories.length,
    });

    await _cache.refreshCategories();
    await _cache.refreshProducts();
  }

  static Future<void> updateProductCategory({
    required String categoryId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Nama kategori harus diisi');

    await _supabase.from('KATEGORI_PRODUK').update({
      'nama_kategori': trimmed,
    }).eq('id', categoryId);

    await _cache.refreshCategories();
    await _cache.refreshProducts();
  }

  static Future<void> deleteProductCategory(String categoryId) async {
    final usedByProduct = await _supabase
        .from('PRODUK')
        .select('id')
        .eq('kategori_id', categoryId)
        .limit(1)
        .maybeSingle();

    if (usedByProduct != null) {
      throw Exception('Kategori masih dipakai oleh produk');
    }

    await _supabase.from('KATEGORI_PRODUK').delete().eq('id', categoryId);
    await _cache.refreshCategories();
    await _cache.refreshProducts();
  }

  static Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    await _cache.refreshExpenseCategories();
    return List<Map<String, dynamic>>.from(_cache.expenseCategories)
      ..sort((a, b) {
        final typeA = a['tipe'] as String? ?? '';
        final typeB = b['tipe'] as String? ?? '';
        if (typeA != typeB) {
          if (typeA == 'business') return -1;
          if (typeB == 'business') return 1;
        }

        final orderA = (a['sort_order'] as num?)?.toInt() ?? 0;
        final orderB = (b['sort_order'] as num?)?.toInt() ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);

        return (a['nama_kategori'] as String? ?? '')
            .compareTo(b['nama_kategori'] as String? ?? '');
      });
  }

  static Future<void> addExpenseCategory({
    required String name,
    required String type,
  }) async {
    final warungId = _cache.warungId;
    if (warungId == null) throw Exception('Warung tidak ditemukan');

    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Nama kategori harus diisi');

    await _supabase.from('KATEGORI_PENGELUARAN').insert({
      'warung_id': warungId,
      'nama_kategori': trimmed,
      'tipe': type,
      'icon': type == 'business' ? 'BelanjaStok.png' : 'LainnyaPribadi.png',
      'sort_order': _cache.expenseCategories.length,
    });

    await _cache.refreshExpenseCategories();
  }

  static Future<void> updateExpenseCategory({
    required String categoryId,
    required String name,
    required String type,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Nama kategori harus diisi');

    await _supabase.from('KATEGORI_PENGELUARAN').update({
      'nama_kategori': trimmed,
      'tipe': type,
      'icon': type == 'business' ? 'BelanjaStok.png' : 'LainnyaPribadi.png',
    }).eq('id', categoryId);

    await _cache.refreshExpenseCategories();
  }

  static Future<void> deleteExpenseCategory(String categoryId) async {
    final usedByExpense = await _supabase
        .from('PENGELUARAN')
        .select('id')
        .eq('kategori_id', categoryId)
        .limit(1)
        .maybeSingle();

    if (usedByExpense != null) {
      throw Exception('Kategori masih dipakai oleh pengeluaran');
    }

    await _supabase.from('KATEGORI_PENGELUARAN').delete().eq('id', categoryId);
    await _cache.refreshExpenseCategories();
  }

  static Future<List<Map<String, dynamic>>> getProductUnits() async {
    await _cache.refreshSatuan();
    return List<Map<String, dynamic>>.from(_cache.satuanItems)
      ..sort((a, b) {
        final orderA = (a['sort_order'] as num?)?.toInt() ?? 0;
        final orderB = (b['sort_order'] as num?)?.toInt() ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return (a['nama_satuan'] as String? ?? '')
            .compareTo(b['nama_satuan'] as String? ?? '');
      });
  }

  static Future<void> addProductUnit(String name) async {
    final warungId = _cache.warungId;
    if (warungId == null) throw Exception('Warung tidak ditemukan');

    final trimmed = name.trim().toUpperCase();
    if (trimmed.isEmpty) throw Exception('Nama satuan harus diisi');

    await _supabase.from('SATUAN_PRODUK').insert({
      'warung_id': warungId,
      'nama_satuan': trimmed,
      'sort_order': _cache.satuanItems.length,
    });

    await _cache.refreshSatuan();
    await _cache.refreshProducts();
  }

  static Future<void> updateProductUnit({
    required String unitId,
    required String oldName,
    required String newName,
  }) async {
    final warungId = _cache.warungId;
    if (warungId == null) throw Exception('Warung tidak ditemukan');

    final trimmed = newName.trim().toUpperCase();
    if (trimmed.isEmpty) throw Exception('Nama satuan harus diisi');

    await _supabase.from('SATUAN_PRODUK').update({
      'nama_satuan': trimmed,
    }).eq('id', unitId);

    if (oldName.trim().toUpperCase() != trimmed) {
      await _supabase.from('PRODUK').update({
        'satuan': trimmed,
      }).eq('warung_id', warungId).eq('satuan', oldName.trim());
    }

    await _cache.refreshSatuan();
    await _cache.refreshProducts();
  }

  static Future<void> deleteProductUnit({
    required String unitId,
    required String unitName,
  }) async {
    final warungId = _cache.warungId;
    if (warungId == null) throw Exception('Warung tidak ditemukan');

    final usedByProduct = await _supabase
        .from('PRODUK')
        .select('id')
        .eq('warung_id', warungId)
        .eq('satuan', unitName)
        .limit(1)
        .maybeSingle();

    if (usedByProduct != null) {
      throw Exception('Satuan masih dipakai oleh produk');
    }

    await _supabase.from('SATUAN_PRODUK').delete().eq('id', unitId);
    await _cache.refreshSatuan();
    await _cache.refreshProducts();
  }

  static Future<Map<String, double>> getOpeningBalances() async {
    final userId = await SessionService.getUserId();
    if (userId == null) throw Exception('Sesi user tidak ditemukan');

    await _cache.refreshWarungData(userId);
    return {
      'saldo_awal': _cache.saldoAwal,
      'uang_kas': _cache.uangKas,
    };
  }

  static Future<void> updateOpeningBalances({
    required double drawerBalance,
    required double cashBalance,
  }) async {
    final warungId = _cache.warungId;
    final userId = await SessionService.getUserId();
    if (warungId == null || userId == null) {
      throw Exception('Warung tidak ditemukan');
    }

    await _supabase.from('WARUNG').update({
      'saldo_awal': drawerBalance,
      'uang_kas': cashBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', warungId);

    await _cache.refreshWarungData(userId);
  }
}
