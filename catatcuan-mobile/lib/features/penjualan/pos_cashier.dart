import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/utils/barcode_helper.dart';
import 'package:catatcuan_mobile/core/utils/product_stock_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';

class PosCashierPage extends StatefulWidget {
  const PosCashierPage({super.key});

  @override
  State<PosCashierPage> createState() => _PosCashierPageState();
}

class _PosCashierPageState extends State<PosCashierPage> {
  final _cache = DataCacheService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedCategoryId;

  // Cart: Product ID -> Quantity
  final Map<String, int> _cart = {};

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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _cache.products.where((p) {
      if (_selectedCategoryId != null && p['kategori_id'] != _selectedCategoryId) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = (p['nama_produk'] as String?)?.toLowerCase() ?? '';
        if (!name.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get _totalItemsInCart {
    int total = 0;
    for (var qty in _cart.values) {
      total += qty;
    }
    return total;
  }

  int get _totalCartPrice {
    int total = 0;
    for (var entry in _cart.entries) {
      final pid = entry.key;
      final qty = entry.value;
      
      final product = _cache.products.firstWhere(
        (p) => p['id'] == pid,
        orElse: () => {},
      );
      
      if (product.isNotEmpty) {
        final price = num.parse((product['harga_jual'] ?? 0).toString()).toInt();
        total += (price * qty);
      }
    }
    return total;
  }

  void _addToCart(Map<String, dynamic> product) {
    final pid = product['id'] as String;
    final currentQty = _cart[pid] ?? 0;

    if (!ProductStockHelper.canAddToCart(
      rawValue: product['stok_saat_ini'],
      currentQty: currentQty,
    )) {
      if (ProductStockHelper.isOutOfStock(product['stok_saat_ini'])) {
        AppToast.showWarning(context, 'Produk sedang habis');
        return;
      }
      AppToast.showWarning(context, 'Stok tidak mencukupi');
      return;
    }

    setState(() {
      _cart[pid] = currentQty + 1;
    });
  }

  void _removeFromCart(String pid) {
    if ((_cart[pid] ?? 0) > 0) {
      setState(() {
        _cart[pid] = _cart[pid]! - 1;
        if (_cart[pid] == 0) {
          _cart.remove(pid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(
              child: Stack(
                children: [
                  _buildProductGrid(formatter),
                  // FAB Add Product
                  Positioned(
                    right: 16,
                    bottom: _totalItemsInCart > 0 ? 80 : 16, // Move up if cart is visible
                    child: FloatingActionButton(
                      onPressed: () async {
                        final result = await context.push('/produk/add');
                        if (result == true) {
                          await _cache.refreshProducts(); // Assuming refreshProducts exists over DataCacheService
                          if (mounted) setState(() {}); 
                        }
                      },
                      backgroundColor: AppTheme.primary,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                  // Bottom Cart Bar
                  if (_totalItemsInCart > 0)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildCartBar(formatter),
                    ),
                ],
              ),
            ),
          ],
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
                  'Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
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
                  hintText: 'Cari Produk...',
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
          GestureDetector(
            onTap: () async {
              final res = await BarcodeHelper.scanOnce(
                context,
                appBarTitle: 'Scan Barcode Produk',
              );
              
              if (!mounted) return;
              
              if (res != null && res != '-1' && res.isNotEmpty) {
                // Find product by barcode
                final product = _cache.products.cast<Map<String, dynamic>>().firstWhere(
                  (p) => (p['barcode'] as String?)?.toLowerCase() == res.toLowerCase(),
                  orElse: () => <String, dynamic>{},
                );

                if (product.isNotEmpty) {
                  _addToCart(product);
                  AppToast.showSuccess(context, 'Berhasil menambahkan ${product['nama_produk']}');
                } else {
                  AppToast.showError(context, 'Produk dengan barcode tersebut tidak ditemukan');
                }
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategoryId = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedCategoryId == null ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedCategoryId == null ? AppTheme.primary : const Color(0xFFD1EDD8),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Semua',
                    style: TextStyle(
                      color: _selectedCategoryId == null ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
          ..._cache.categories.map((cat) {
            final isSelected = _selectedCategoryId == cat['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat['id'] as String?),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : const Color(0xFFD1EDD8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (cat['nama_kategori'] as String?) ?? 'Unknown',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductGrid(NumberFormat formatter) {
    if (_filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Produk tidak ditemukan',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 16, 
        // Extra padding at bottom to clear FAB and Cart Bar
        bottom: _totalItemsInCart > 0 ? 100 : 80 
      ),
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final stock = ProductStockHelper.parseStock(product['stok_saat_ini']);
        final isUnlimited = ProductStockHelper.isUnlimited(stock);
        final isOutOfStock = ProductStockHelper.isOutOfStock(stock);
        final price = num.parse((product['harga_jual'] ?? 0).toString()).toInt();
        
        String iconName = 'Lainya.png';
        if (product['KATEGORI_PRODUK'] != null) {
           iconName = (product['KATEGORI_PRODUK'] as Map<String, dynamic>?)?['icon'] as String? ?? 'Lainya.png';
        }

        return Container(
            height: 80,
            decoration: BoxDecoration(
              color: isOutOfStock ? Colors.grey[200] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
            ),
            child: Row(
              children: [
                // Icon Area
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.grey[300] : const Color(0xFFF2F6FF),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: isOutOfStock ? 0.5 : 1.0,
                      child: Image.asset(
                        _resolveIconPath(iconName),
                        width: 45,
                        height: 45,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Text Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (product['nama_produk'] as String?) ?? '-',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isOutOfStock ? Colors.grey : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatter.format(price),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isOutOfStock ? Colors.grey : AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• Stok: ${ProductStockHelper.formatStockLabel(stock, unlimitedLabel: 'Unlimited')}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: isOutOfStock
                                          ? Colors.red
                                          : isUnlimited
                                              ? AppTheme.primary
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Quantity Controls instead of just tapping the row
                        if ((_cart[product['id'] as String] ?? 0) > 0)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _removeFromCart(product['id'] as String),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove, size: 20, color: Colors.black54),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${_cart[product['id'] as String]}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: isOutOfStock ? null : () => _addToCart(product),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: isOutOfStock ? null : () => _addToCart(product),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isOutOfStock ? Colors.grey[300] : AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
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
        },
      );
    }

  Widget _buildCartBar(NumberFormat formatter) {
    return GestureDetector(
      onTap: () async {
        if (_cart.isEmpty) {
          AppToast.showWarning(context, 'Keranjang masih kosong');
          return;
        }
        final updatedCart = await context.push<Map<String, int>>('/transaksi/checkout', extra: _cart);
        if (updatedCart != null) {
          setState(() {
            _cart.clear();
            _cart.addAll(updatedCart);
          });
        }
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_basket_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_totalItemsInCart Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      formatter.format(_totalCartPrice),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Row(
              children: [
                Text(
                  'CHECKOUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            )
          ],
        ),
      ),
    );
  }
}
