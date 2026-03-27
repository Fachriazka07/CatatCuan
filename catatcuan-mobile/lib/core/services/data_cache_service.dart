import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized in-memory data cache to eliminate repeated Supabase fetches.
///
/// All shared data (warung, categories, satuan, products) is loaded ONCE
/// during splash screen, then reused across all pages.
///
/// Cache invalidation happens automatically on CRUD operations.
class DataCacheService {
  // Singleton
  DataCacheService._();
  static final DataCacheService _instance = DataCacheService._();
  static DataCacheService get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ==================== CACHED DATA ====================

  /// Warung info
  String? warungId;
  String? userName;
  String? warungName;
  double saldoAwal = 0;
  double uangKas = 0;
  double uangKasOperasional = 0;

  /// Kategori Produk (user's categories for this warung)
  List<Map<String, dynamic>> categories = [];

  /// Kategori Pengeluaran (user's categories for this warung)
  List<Map<String, dynamic>> expenseCategories = [];

  /// Satuan Produk (user's satuan for this warung)
  List<Map<String, dynamic>> satuanItems = [];

  /// All products for this warung
  List<Map<String, dynamic>> products = [];

  /// Whether initial load has completed
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ==================== LOAD ALL DATA ====================

  /// Load all cacheable data. Called once during splash screen.
  Future<void> loadAll(String userId) async {
    try {
      // 1. Load warung data
      await refreshWarungData(userId);

      // 2. Sync master data (categories & satuan)
      await syncMasterCategories();
      await syncMasterSatuan();
      await syncMasterExpenseCategories();

      // 3. Load categories
      await refreshCategories();
      await refreshExpenseCategories();

      // 4. Load satuan
      await refreshSatuan();

      // 5. Load products
      await refreshProducts();

      _isLoaded = true;
      debugPrint('[DataCache] All data loaded: ${categories.length} categories, '
          '${expenseCategories.length} expense categories, '
          '${satuanItems.length} satuan, ${products.length} products');
    } catch (e) {
      debugPrint('[DataCache] Error loading data: $e');
      rethrow;
    }
  }

  // ==================== SYNC MASTER DATA ====================

  /// Sync master categories from admin → user's KATEGORI_PRODUK.
  /// Handles add (new active), update (name/icon changed), delete (deactivated).
  Future<void> syncMasterCategories() async {
    if (warungId == null) return;

    try {
      final allMasterData = await _supabase
          .from('MASTER_KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order, is_active');

      final userData = await _supabase
          .from('KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order, master_kategori_id')
          .eq('warung_id', warungId!);

      final userByMasterId = <String, Map<String, dynamic>>{};
      for (final u in List<Map<String, dynamic>>.from(userData)) {
        final mid = u['master_kategori_id']?.toString();
        if (mid != null) userByMasterId[mid] = u;
      }

      for (final master in List<Map<String, dynamic>>.from(allMasterData)) {
        final masterId = master['id'].toString();
        final isActive = master['is_active'] == true;
        final existing = userByMasterId[masterId];

        if (isActive) {
          if (existing == null) {
            await _supabase.from('KATEGORI_PRODUK').insert({
              'warung_id': warungId,
              'nama_kategori': master['nama_kategori'],
              'icon': master['icon'],
              'sort_order': master['sort_order'] ?? 0,
              'master_kategori_id': masterId,
            });
          } else {
            if (existing['nama_kategori'] != master['nama_kategori'] ||
                existing['icon'] != master['icon']) {
              await _supabase.from('KATEGORI_PRODUK').update({
                'nama_kategori': master['nama_kategori'],
                'icon': master['icon'],
                'sort_order': master['sort_order'] ?? 0,
              }).eq('id', existing['id'] as Object);
            }
          }
        } else {
          if (existing != null) {
            await _supabase
                .from('KATEGORI_PRODUK')
                .delete()
                .eq('id', existing['id'] as Object);
          }
        }
      }
    } catch (e) {
      debugPrint('[DataCache] Error syncing master categories: $e');
    }
  }

  /// Sync master expense categories from admin → user's KATEGORI_PENGELUARAN.
  Future<void> syncMasterExpenseCategories() async {
    if (warungId == null) return;

    try {
      final allMasterData = await _supabase
          .from('MASTER_KATEGORI_PENGELUARAN')
          .select('id, nama_kategori, tipe, icon, sort_order, is_active');

      final userData = await _supabase
          .from('KATEGORI_PENGELUARAN')
          .select('id, nama_kategori, tipe, icon, sort_order, master_kategori_id')
          .eq('warung_id', warungId!);

      final userByMasterId = <String, Map<String, dynamic>>{};
      for (final u in List<Map<String, dynamic>>.from(userData)) {
        final mid = u['master_kategori_id']?.toString();
        if (mid != null) userByMasterId[mid] = u;
      }

      for (final master in List<Map<String, dynamic>>.from(allMasterData)) {
        final masterId = master['id'].toString();
        final isActive = master['is_active'] == true;
        final existing = userByMasterId[masterId];

        if (isActive) {
          if (existing == null) {
            await _supabase.from('KATEGORI_PENGELUARAN').insert({
              'warung_id': warungId,
              'nama_kategori': master['nama_kategori'],
              'tipe': master['tipe'],
              'icon': master['icon'],
              'sort_order': master['sort_order'] ?? 0,
              'master_kategori_id': masterId,
            });
          } else {
            if (existing['nama_kategori'] != master['nama_kategori'] ||
                existing['icon'] != master['icon'] ||
                existing['tipe'] != master['tipe']) {
              await _supabase.from('KATEGORI_PENGELUARAN').update({
                'nama_kategori': master['nama_kategori'],
                'tipe': master['tipe'],
                'icon': master['icon'],
                'sort_order': master['sort_order'] ?? 0,
              }).eq('id', existing['id'] as Object);
            }
          }
        } else {
          if (existing != null) {
            // Check if there are expenses using this category
            final expenses = await _supabase
                .from('PENGELUARAN')
                .select('id')
                .eq('kategori_id', existing['id'] as Object)
                .limit(1);
            
            if ((expenses as List).isEmpty) {
              await _supabase
                  .from('KATEGORI_PENGELUARAN')
                  .delete()
                  .eq('id', existing['id'] as Object);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[DataCache] Error syncing master expense categories: $e');
    }
  }

  /// Sync master satuan from admin → user's SATUAN_PRODUK.
  Future<void> syncMasterSatuan() async {
    if (warungId == null) return;

    try {
      final allMasterData = await _supabase
          .from('MASTER_SATUAN')
          .select('id, nama_satuan, sort_order, is_active');

      final userData = await _supabase
          .from('SATUAN_PRODUK')
          .select('id, nama_satuan, sort_order, master_satuan_id')
          .eq('warung_id', warungId!);

      final userByMasterId = <String, Map<String, dynamic>>{};
      for (final u in List<Map<String, dynamic>>.from(userData)) {
        final mid = u['master_satuan_id']?.toString();
        if (mid != null) userByMasterId[mid] = u;
      }

      for (final master in List<Map<String, dynamic>>.from(allMasterData)) {
        final masterId = master['id'].toString();
        final isActive = master['is_active'] == true;
        final existing = userByMasterId[masterId];

        if (isActive) {
          if (existing == null) {
            await _supabase.from('SATUAN_PRODUK').insert({
              'warung_id': warungId,
              'nama_satuan': master['nama_satuan'],
              'sort_order': master['sort_order'] ?? 0,
              'master_satuan_id': masterId,
            });
          } else {
            if (existing['nama_satuan'] != master['nama_satuan']) {
              await _supabase.from('SATUAN_PRODUK').update({
                'nama_satuan': master['nama_satuan'],
                'sort_order': master['sort_order'] ?? 0,
              }).eq('id', existing['id'] as Object);
            }
          }
        } else {
          if (existing != null) {
            await _supabase
                .from('SATUAN_PRODUK')
                .delete()
                .eq('id', existing['id'] as Object);
          }
        }
      }
    } catch (e) {
      debugPrint('[DataCache] Error syncing master satuan: $e');
    }
  }

  // ==================== REFRESH METHODS ====================

  /// Refresh warung data from Supabase.
  Future<void> refreshWarungData(String userId) async {
    try {
      final warungData = await _supabase
          .from('WARUNG')
          .select('id, nama_warung, nama_pemilik, saldo_awal, uang_kas, uang_kas_operasional')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (warungData == null) {
        throw Exception('Data warung tidak ditemukan untuk user ini');
      }

      warungId = warungData['id'] as String;
      userName = (warungData['nama_pemilik'] as String?) ?? 'User';
      warungName = warungData['nama_warung'] as String?;
      saldoAwal = (warungData['saldo_awal'] as num?)?.toDouble() ?? 0;
      uangKas = (warungData['uang_kas'] as num?)?.toDouble() ?? 0;
      uangKasOperasional = (warungData['uang_kas_operasional'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint('[DataCache] Error refreshing warung data: $e');
      rethrow;
    }
  }

  /// Refresh categories from Supabase into cache.
  Future<void> refreshCategories() async {
    if (warungId == null) return;
    try {
      final data = await _supabase
          .from('KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order, master_kategori_id')
          .eq('warung_id', warungId!)
          .order('sort_order', ascending: true);

      categories = List<Map<String, dynamic>>.from(data);
      debugPrint('[DataCache] Categories refreshed: ${categories.length}');
    } catch (e) {
      debugPrint('[DataCache] Error refreshing categories: $e');
    }
  }

  /// Refresh expense categories from Supabase into cache.
  Future<void> refreshExpenseCategories() async {
    if (warungId == null) return;
    try {
      final data = await _supabase
          .from('KATEGORI_PENGELUARAN')
          .select('id, nama_kategori, icon, tipe, sort_order, master_kategori_id')
          .eq('warung_id', warungId!)
          .order('tipe', ascending: false) // Business first
          .order('sort_order', ascending: true);

      expenseCategories = List<Map<String, dynamic>>.from(data);
      debugPrint('[DataCache] Expense categories refreshed: ${expenseCategories.length}');
    } catch (e) {
      debugPrint('[DataCache] Error refreshing expense categories: $e');
    }
  }

  /// Refresh satuan from Supabase into cache.
  Future<void> refreshSatuan() async {
    if (warungId == null) return;
    try {
      final data = await _supabase
          .from('SATUAN_PRODUK')
          .select('id, nama_satuan, sort_order, master_satuan_id')
          .eq('warung_id', warungId!)
          .order('sort_order', ascending: true);

      satuanItems = List<Map<String, dynamic>>.from(data);
      debugPrint('[DataCache] Satuan refreshed: ${satuanItems.length}');
    } catch (e) {
      debugPrint('[DataCache] Error refreshing satuan: $e');
    }
  }

  /// Refresh products from Supabase into cache.
  Future<void> refreshProducts() async {
    if (warungId == null) return;
    try {
      final data = await _supabase
          .from('PRODUK')
          .select('*, KATEGORI_PRODUK(nama_kategori, icon)')
          .eq('warung_id', warungId!)
          .order('nama_produk', ascending: true);

      products = List<Map<String, dynamic>>.from(data);
      debugPrint('[DataCache] Products refreshed: ${products.length}');
    } catch (e) {
      debugPrint('[DataCache] Error refreshing products: $e');
    }
  }

  // ==================== LOCAL CACHE UPDATES ====================

  /// Add a product to local cache (after successful insert to Supabase).
  void addProductToCache(Map<String, dynamic> product) {
    products.add(product);
    products.sort((a, b) =>
        (a['nama_produk'] as String? ?? '').compareTo(b['nama_produk'] as String? ?? ''));
  }

  /// Update a product in local cache (after successful update to Supabase).
  void updateProductInCache(String productId, Map<String, dynamic> updatedData) {
    final index = products.indexWhere((p) => p['id'] == productId);
    if (index != -1) {
      products[index] = {...products[index], ...updatedData};
    }
  }

  /// Remove a product from local cache (after successful delete from Supabase).
  void removeProductFromCache(String productId) {
    products.removeWhere((p) => p['id'] == productId);
  }

  /// Add a category to local cache.
  void addCategoryToCache(Map<String, dynamic> category) {
    categories.add(category);
  }

  /// Add a satuan to local cache.
  void addSatuanToCache(Map<String, dynamic> satuan) {
    satuanItems.add(satuan);
  }

  // ==================== CLEAR ====================

  /// Clear all cached data (on logout).
  void clear() {
    warungId = null;
    userName = null;
    warungName = null;
    saldoAwal = 0;
    uangKas = 0;
    uangKasOperasional = 0;
    categories = [];
    expenseCategories = [];
    satuanItems = [];
    products = [];
    _isLoaded = false;
    debugPrint('[DataCache] Cache cleared');
  }
}
