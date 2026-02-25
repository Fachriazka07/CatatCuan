import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Map<String, List<Map<String, dynamic>>> groupedProducts = {};
  
  String _selectedCategoryFilter = 'Semua Kategori';
  List<String> _availableCategories = ['Semua Kategori'];
  int _maxCategoriesShown = 3;
  int _maxItemsPerCategory = 10;
  
  final TextEditingController _searchController = TextEditingController();

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
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return;

      final userData = await supabase
          .from('WARUNG')
          .select('id')
          .eq('user_id', userId)
          .single();

      final warungId = userData['id'];

      final data = await supabase
          .from('PRODUK')
          .select('*, KATEGORI_PRODUK(nama_kategori, icon)')
          .eq('warung_id', warungId)
          .order('nama_produk', ascending: true);

      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        
        _availableCategories = ['Semua Kategori'];
        for (var p in products) {
          final catName = (p['KATEGORI_PRODUK']?['nama_kategori'] ?? 'Lainnya').toString();
          if (!_availableCategories.contains(catName)) {
            _availableCategories.add(catName);
          }
        }
        
        _filterProducts();
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    
    final filteredList = products.where((product) {
      final name = (product['nama_produk'] ?? '').toString().toLowerCase();
      final category = (product['KATEGORI_PRODUK']?['nama_kategori'] ?? 'Lainnya').toString().toLowerCase();
      
      bool matchesQuery = name.contains(query) || category.contains(query);
      bool matchesCategory = _selectedCategoryFilter == 'Semua Kategori' || category == _selectedCategoryFilter.toLowerCase();
      
      return matchesQuery && matchesCategory;
    }).toList();
    
    // Group them
    Map<String, List<Map<String, dynamic>>> newGrouped = {};
    for (var product in filteredList) {
      final categoryName = (product['KATEGORI_PRODUK']?['nama_kategori'] ?? 'Lainnya').toString().toUpperCase();
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

  String _formatCurrency(num value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white background based on typical app use
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterDropdown(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchProducts,
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
        width: 100,
        height: 100,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await context.push('/produk/add');
            if (result == true) {
              _fetchProducts();
            }
          },
          backgroundColor: AppTheme.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 44, height: 8, color: Colors.white),
              Container(width: 8, height: 44, color: Colors.white),
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
            color: Colors.black.withOpacity(0.15),
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
          // Filter icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          // Warning icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 22),
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
            color: Colors.grey.withOpacity(0.5),
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

    List<Widget> listWidgets = [];
    
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
      
      List<Widget> cardItems = [];
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
                    color: Colors.black.withOpacity(0.05),
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
    final satuan = product['satuan'] ?? 'PCS';
    final stok = product['stok_saat_ini'] ?? 0;
    final nama = (product['nama_produk'] as String? ?? 'NAMA PRODUK').toUpperCase();
    
    String iconName = product['KATEGORI_PRODUK']?['icon'] ?? 'Lainya.png';
    String iconPath = _resolveIconPath(iconName);

    return Container(
      height: 70, 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1EDD8)),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(iconPath, fit: BoxFit.contain), 
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
          
          // Price
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _formatCurrency(product['harga_jual'] ?? 0),
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
    );
  }
}

