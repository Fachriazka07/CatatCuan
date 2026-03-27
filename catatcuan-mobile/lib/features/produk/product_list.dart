import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:catatcuan_mobile/core/utils/barcode_helper.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> with TickerProviderStateMixin {
  final _cache = DataCacheService.instance;
  bool isLoading = false;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Map<String, List<Map<String, dynamic>>> groupedProducts = {};
  
  String _selectedCategoryFilter = 'Semua Kategori';
  List<String> _availableCategories = ['Semua Kategori'];
  int _maxCategoriesShown = 3;
  int _maxItemsPerCategory = 10;
  
  final TextEditingController _searchController = TextEditingController();

  // Low stock warning
  static const int _lowStockThreshold = 3; // stock < 3 = low stock
  late AnimationController _blinkController;
  List<Map<String, dynamic>> _lowStockProducts = [];

  static const Set<String> _validIcons = {
    'BumbuDapur.png', 'Cemilan.png', 'Lainya.png', 'Minuman.png',
    'Obat.png', 'PerlengkapanMandi.png', 'Rokok.png', 'Sembako.png',
  };

  String _resolveIconPath(String? iconName) {
    if (iconName == null || iconName.isEmpty || !_validIcons.contains(iconName)) {
      return 'assets/icon/produk-icon/Lainya.png';
    }
    return 'assets/icon/produk-icon/$iconName';
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadFromCache();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Load products from cache — instant, no network call.
  void _loadFromCache() {
    products = List<Map<String, dynamic>>.from(_cache.products);
    
    _availableCategories = ['Semua Kategori'];
    for (var p in products) {
      final catName = ((p['KATEGORI_PRODUK'] as Map<String, dynamic>?)?['nama_kategori'] as String? ?? 'Lainnya');
      if (!_availableCategories.contains(catName)) {
        _availableCategories.add(catName);
      }
    }

    // Detect low stock products
    _lowStockProducts = products.where((p) {
      final stock = (p['stok_saat_ini'] as num?)?.toInt() ?? 0;
      return stock < _lowStockThreshold;
    }).toList();


    
    _filterProducts();
  }

  /// Pull-to-refresh: fetch fresh data from Supabase then update cache.
  Future<void> _refreshProducts() async {
    setState(() => isLoading = true);
    try {
      await _cache.refreshProducts();
      _loadFromCache();
    } catch (e) {
      debugPrint('Error refreshing products: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    
    final filteredList = products.where((product) {
      final name = (product['nama_produk'] ?? '').toString().toLowerCase();
      final barcode = (product['barcode'] ?? '').toString().toLowerCase();
      final category = ((product['KATEGORI_PRODUK'] as Map<String, dynamic>?)?['nama_kategori'] as String? ?? 'Lainnya').toLowerCase();
      
      final bool matchesQuery = name.contains(query) || barcode.contains(query) || category.contains(query);
      final bool matchesCategory = _selectedCategoryFilter == 'Semua Kategori' || category == _selectedCategoryFilter.toLowerCase();
      
      return matchesQuery && matchesCategory;
    }).toList();
    
    // Group them
    final Map<String, List<Map<String, dynamic>>> newGrouped = {};
    for (var product in filteredList) {
      final categoryName = ((product['KATEGORI_PRODUK'] as Map<String, dynamic>?)?['nama_kategori'] as String? ?? 'Lainnya').toUpperCase();
      if (!newGrouped.containsKey(categoryName)) {
        newGrouped[categoryName] = [];
      }
      newGrouped[categoryName]!.add(product);
    }
    
    setState(() {
      filteredProducts = filteredList;
      groupedProducts = newGrouped;
    });
  }

  void _showLowStockPopup() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stok Menipis',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_lowStockProducts.length} produk perlu direstok',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _lowStockProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final p = _lowStockProducts[index];
                    final name = (p['nama_produk'] as String? ?? 'Produk').toUpperCase();
                    final stock = (p['stok_saat_ini'] as num?)?.toInt() ?? 0;
                    final satuan = (p['satuan'] as String?) ?? 'PCS';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      'Sisa: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    Text(
                                      '$stock $satuan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: stock == 0 ? const Color(0xFFDC2626) : const Color(0xFFFF6B00),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (stock == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'HABIS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white background based on typical app use
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterDropdown(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshProducts,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : _buildProductList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: _showAddOptions,
          backgroundColor: AppTheme.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 42),
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              onTap: () async {
                Navigator.pop(ctx);
                final result = await context.push('/produk/add');
                if (result == true) {
                  await _cache.refreshProducts();
                  _loadFromCache();
                  if (mounted) setState(() {});
                }
              },
              icon: Icons.add_box_rounded,
              iconBg: AppTheme.primary.withValues(alpha: 0.1),
              iconColor: AppTheme.primary,
              title: 'Tambah Produk',
              subtitle: 'Input data produk secara manual',
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              onTap: () async {
                Navigator.pop(ctx); // Close bottom sheet FIRST
                
                final res = await BarcodeHelper.scanOnce(
                  context,
                  appBarTitle: 'Scan Barcode Produk',
                );
                
                if (!mounted) return;
                
                if (res != null && res != '-1' && res.isNotEmpty) {
                  final result = await context.push('/produk/add', extra: {'barcode': res});
                  if (result == true) {
                    await _cache.refreshProducts();
                    _loadFromCache();
                    if (mounted) setState(() {});
                  }
                }
              },
              icon: Icons.qr_code_scanner_rounded,
              iconBg: const Color(0xFFF8BD00).withValues(alpha: 0.1),
              iconColor: const Color(0xFFF8BD00),
              title: 'Scan Produk',
              subtitle: 'Tambah produk dengan scan barcode',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required VoidCallback onTap,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.grey.withValues(alpha: 0.05),
        highlightColor: Colors.grey.withValues(alpha: 0.05),
        splashColor: Colors.grey.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField( 
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ketik Nama Produk.....',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF13B158), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Scan icon
          GestureDetector(
            onTap: () async {
              final res = await BarcodeHelper.scanOnce(
                context,
                appBarTitle: 'Scan Barcode Produk',
              );
              
              if (!mounted) return;
              
              if (res != null && res != '-1' && res.isNotEmpty) {
                _searchController.text = res;
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          // Warning icon with notification badge
          GestureDetector(
            onTap: _lowStockProducts.isNotEmpty ? _showLowStockPopup : null,
            child: FadeTransition(
              opacity: _lowStockProducts.isNotEmpty
                  ? Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController)
                  : const AlwaysStoppedAnimation(0.4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _lowStockProducts.isNotEmpty ? Colors.red : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.white, size: 22),
                  ),
                  if (_lowStockProducts.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B00),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '${_lowStockProducts.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 8),
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryFilter,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 24),
          isExpanded: true,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500, // medium
            fontFamily: 'Poppins',
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategoryFilter = newValue;
                _maxCategoriesShown = 3;
                _maxItemsPerCategory = 10;
                _filterProducts();
              });
            }
          },
          items: _availableCategories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/main-page/icon/package.png',
            width: 100,
            height: 100,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Belum ada produk'
                : 'Produk tidak ditemukan',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final categoryKeys = groupedProducts.keys.toList();
    // Sort keys alphabetically
    categoryKeys.sort();
    
    // Sort items inside each category by name
    for (var key in categoryKeys) {
      groupedProducts[key]!.sort((a, b) {
        final aName = (a['nama_produk'] as String? ?? '').toLowerCase();
        final bName = (b['nama_produk'] as String? ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
    }

    final int catsToShow = (_maxCategoriesShown < categoryKeys.length) ? _maxCategoriesShown : categoryKeys.length;
    
    bool hasMore = false;
    if (categoryKeys.length > _maxCategoriesShown) hasMore = true;

    final List<Widget> listWidgets = [];
    
    for (int i = 0; i < catsToShow; i++) {
      final catName = categoryKeys[i];
      final items = groupedProducts[catName]!;
      
      if (items.length > _maxItemsPerCategory) hasMore = true;
      
      final itemsToShow = (items.length > _maxItemsPerCategory) ? _maxItemsPerCategory : items.length;
      
      listWidgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            catName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500, // medium
              color: Color(0xFF374151),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
      
      final List<Widget> cardItems = [];
      for (int j = 0; j < itemsToShow; j++) {
        cardItems.add(_buildProductCardContent(items[j]));
        if (j < itemsToShow - 1) {
          cardItems.add(const Divider(height: 1, thickness: 1, color: Color(0xFFD1EDD8)));
        }
      }
      
      listWidgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
          ),
          child: Column(
            children: cardItems,
          ),
        )
      );
    }
    
    if (hasMore) {
      listWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _maxCategoriesShown += 3;
                _maxItemsPerCategory += 10;
              });
            },
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Load More',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    listWidgets.add(const SizedBox(height: 100));

    return ListView(
      children: listWidgets,
    );
  }

  Widget _buildProductCardContent(Map<String, dynamic> product) {
    final satuan = (product['satuan'] as String?) ?? 'PCS';
    final stok = product['stok_saat_ini'] ?? 0;
    final nama = (product['nama_produk'] as String? ?? 'NAMA PRODUK').toUpperCase();
    
    final String iconName = (product['KATEGORI_PRODUK'] as Map<String, dynamic>?)?['icon'] as String? ?? 'Lainya.png';
    final String iconPath = _resolveIconPath(iconName);

    return InkWell(
      onTap: () async {
        final result = await context.push('/produk/detail', extra: product);
        if (result == true) {
          await _cache.refreshProducts();
          _loadFromCache();
          if (mounted) setState(() {});
        }
      },
      child: Container(
        height: 70, 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product icon with low stock blinking indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1EDD8)),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(iconPath, fit: BoxFit.contain), 
                ),
                if ((stok as num).toInt() < _lowStockThreshold)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.2, end: 1.0).animate(_blinkController),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500, // medium
                      color: Color(0xFFF8BD00), // secondary color
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const SizedBox(
                        width: 70,
                        child: Text(
                          'Sisa Stok',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500, // medium
                            color: Color(0xFF6B7280),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ': $stok $satuan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500, // medium
                            color: Color(0xFF6B7280),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Price aligned to top right
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _formatCurrency((product['harga_jual'] as num?) ?? 0),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500, // medium
                      color: AppTheme.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

