import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.initialCart});
  final Map<String, int> initialCart;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cache = DataCacheService.instance;
  final _supabase = Supabase.instance.client;
  final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late Map<String, int> _cart;
  List<Map<String, dynamic>> _cartProducts = [];

  // Controllers
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _uangDiterimaController = TextEditingController();
  final TextEditingController _uangMukaController = TextEditingController();

  // State
  String _paymentMethod = 'TUNAI'; // 'TUNAI' | 'HUTANG'
  num _totalPrice = 0;
  num _discount = 0;

  // Hutang Data
  List<Map<String, dynamic>> _customers = [];
  String? _selectedCustomerId;
  DateTime? _jatuhTempo;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cart = Map<String, int>.from(widget.initialCart);
    _loadCartProducts();
    _fetchCustomers();

    _discountController.addListener(_calculateTotal);
    _uangDiterimaController.addListener(
      () => setState(() {}),
    ); // To reactive kembalian updates
    _uangMukaController.addListener(
      () => setState(() {}),
    ); // To reactive sisa hutang updates
  }

  @override
  void dispose() {
    _discountController.dispose();
    _uangDiterimaController.dispose();
    _uangMukaController.dispose();
    super.dispose();
  }

  void _loadCartProducts() {
    _cartProducts = _cache.products.where((p) {
      final id = p['id'] as String;
      return _cart.containsKey(id) && _cart[id]! > 0;
    }).toList();
    _calculateTotal();
  }

  Future<void> _fetchCustomers() async {
    try {
      if (_cache.warungId == null) return;

      final response = await _supabase
          .from('PELANGGAN')
          .select('id, nama, phone')
          .eq('warung_id', _cache.warungId!)
          .order('nama', ascending: true);

      if (mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    }
  }

  void _calculateTotal() {
    num subtotal = 0;
    for (var p in _cartProducts) {
      final pid = p['id'] as String;
      final price = num.parse((p['harga_jual'] ?? 0).toString());
      final qty = _cart[pid] ?? 0;
      subtotal += (price * qty);
    }

    // Parse discount safely
    final discountStr = _discountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    _discount = int.tryParse(discountStr) ?? 0;

    setState(() {
      _totalPrice = subtotal;
    });
  }

  num get _netTotal => (_totalPrice - _discount).clamp(0, double.infinity);

  Map<String, dynamic>? _findProductById(String pid) {
    for (final product in _cache.products) {
      if (product['id'] == pid) {
        return product;
      }
    }
    return null;
  }

  String _buildHutangNotes(List<Map<String, dynamic>> items) {
    final buffer = StringBuffer();

    for (final item in items) {
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      final hargaSatuan = num.parse((item['harga_satuan'] ?? 0).toString());
      final subtotal = num.parse((item['subtotal'] ?? 0).toString());
      final namaProduk = item['nama_produk']?.toString() ?? 'Produk';

      buffer.writeln(
        '$namaProduk ${qty}x ${_formatter.format(hargaSatuan)} = ${_formatter.format(subtotal)}',
      );
    }

    if (_discount > 0) {
      buffer.writeln('Diskon: ${_formatter.format(_discount)}');
    }

    return buffer.toString().trim();
  }

  Future<void> _insertBukuKasPenjualan({
    required String warungId,
    required String penjualanId,
    required DateTime tanggal,
    required double amount,
    required String invoiceNo,
    required String keterangan,
  }) async {
    if (amount <= 0) return;

    final saldoSetelah = _cache.saldoAwal + _cache.uangKas;

    await _supabase.from('BUKU_KAS').insert({
      'warung_id': warungId,
      'tanggal': tanggal.toUtc().toIso8601String(),
      'tipe': 'masuk',
      'sumber': 'penjualan',
      'reference_id': penjualanId,
      'reference_type': 'PENJUALAN',
      'amount': amount,
      'saldo_setelah': saldoSetelah,
      'keterangan': '$invoiceNo - $keterangan',
    });
  }

  void _updateQty(String pid, int delta) {
    final currentQty = _cart[pid] ?? 0;
    final newQty = currentQty + delta;

    // Validations
    if (newQty < 0) return;

    if (delta > 0) {
      final product = _findProductById(pid);
      final stock =
          num.parse((product?['stok_saat_ini'] ?? 0).toString()).toInt();

      if (currentQty >= stock && stock > 0) {
        AppToast.showWarning(context, 'Stok tidak mencukupi');
        return;
      }

      if (stock <= 0) {
        AppToast.showWarning(context, 'Produk sedang habis');
        return;
      }
    }

    if (newQty == 0) {
      _cart.remove(pid);
    } else {
      _cart[pid] = newQty;
    }

    setState(() {
      _loadCartProducts();
    });
  }

  String _resolveIconPath(String? iconName) {
    final validIcons = [
      'Bahan_Bangunan.png',
      'Bahan_Kue.png',
      'Buku_ATK.png',
      'Bumbu_Dapur.png',
      'Buah.png',
      'Cepat_Saji.png',
      'Daging.png',
      'Dessert.png',
      'Elektronik.png',
      'Fashion.png',
      'Frozen_Food.png',
      'Gadget.png',
      'Gas.png',
      'Kecantikan.png',
      'Kesehatan.png',
      'Lainya.png',
      'Layanan.png',
      'Mainan.png',
      'Makanan_Hewan.png',
      'Pakaian_Anak.png',
      'Peralatan_Mancing.png',
      'Peralatan_Olahraga.png',
      'Perawatan_Kendaraan.png',
      'Sayuran.png',
      'Sembako.png',
      'Snack.png',
      'Minuman.png',
      'Aksesoris.png',
    ];
    if (iconName == null ||
        iconName.isEmpty ||
        !validIcons.contains(iconName)) {
      return 'assets/icon/produk-icon/Lainya.png';
    }
    return 'assets/icon/produk-icon/$iconName';
  }

  Future<void> _processPayment() async {
    if (_cartProducts.isEmpty) {
      AppToast.showError(context, 'Keranjang kosong!');
      return;
    }

    if (_paymentMethod == 'HUTANG') {
      if (_selectedCustomerId == null) {
        AppToast.showWarning(
          context,
          'Pilih pelanggan untuk pembayaran hutang!',
        );
        return;
      }
    } else if (_paymentMethod == 'TUNAI') {
      final uangStr = _uangDiterimaController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final uang = num.tryParse(uangStr) ?? 0;

      if (uang < _netTotal) {
        AppToast.showWarning(
          context,
          'Uang yang diterima kurang dari total tagihan!',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final warungId = _cache.warungId;
      if (warungId == null) throw Exception('Warung ID tidak ditemukan');

      final timestamp = DateTime.now();
      final String invoiceNo =
          'INV-${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}-${timestamp.millisecondsSinceEpoch.toString().substring(7)}';

      final uangStr = _uangDiterimaController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final uangDiterima = num.tryParse(uangStr) ?? 0;

      final dpStr = _uangMukaController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final dp = num.tryParse(dpStr) ?? 0;

      // 1. Insert PENJUALAN
      final penjualanData = {
        'warung_id': warungId,
        'pelanggan_id': _paymentMethod == 'HUTANG' ? _selectedCustomerId : null,
        'invoice_no': invoiceNo,
        'total_amount': _totalPrice,
        'amount_paid': _paymentMethod == 'TUNAI' ? uangDiterima : dp,
        'amount_change': _paymentMethod == 'TUNAI'
            ? (uangDiterima - _netTotal).clamp(0, double.infinity)
            : 0,
        'payment_method': _paymentMethod.toLowerCase(), // 'tunai' or 'hutang'
        'status': 'completed',
        'notes': _discount > 0 ? 'Diskon: $_discount' : null,
      };

      final insertedPenjualan = await _supabase
          .from('PENJUALAN')
          .insert(penjualanData)
          .select()
          .single();
      final penjualanId = insertedPenjualan['id'];

      // 2. Insert PENJUALAN_ITEM (with harga_modal for profit tracking)
      final List<Map<String, dynamic>> itemsToInsert = [];
      double totalProfit = 0;
      for (var p in _cartProducts) {
        final pid = p['id'] as String;
        final qty = _cart[pid] ?? 0;
        final price = num.parse((p['harga_jual'] ?? 0).toString());
        final hargaModal = num.parse((p['harga_modal'] ?? 0).toString());
        final itemProfit = (price - hargaModal) * qty;
        totalProfit += itemProfit;

        itemsToInsert.add({
          'penjualan_id': penjualanId,
          'produk_id': pid,
          'nama_produk': p['nama_produk'],
          'quantity': qty,
          'harga_satuan': price,
          'harga_modal': hargaModal,
          'subtotal': price * qty,
        });
      }

      await _supabase.from('PENJUALAN_ITEM').insert(itemsToInsert);

      // Update PENJUALAN with profit
      await _supabase
          .from('PENJUALAN')
          .update({'profit': totalProfit})
          .eq('id', penjualanId);

      // 3. Insert HUTANG if necessary
      if (_paymentMethod == 'HUTANG') {
        final sisaHutang = _netTotal - dp;
        final hutangNotes = _buildHutangNotes(itemsToInsert);

        final hutangData = {
          'warung_id': warungId,
          'pelanggan_id': _selectedCustomerId,
          'penjualan_id': penjualanId,
          'catatan': hutangNotes,
          'amount_awal': _netTotal,
          'amount_terbayar': dp,
          'amount_sisa': sisaHutang,
          'tanggal_jatuh_tempo': _jatuhTempo?.toIso8601String().split('T')[0],
          'status': sisaHutang <= 0 ? 'lunas' : 'belum_lunas',
          'jenis': 'PIUTANG',
        };

        await _supabase.from('HUTANG').insert(hutangData);

        // Update PELANGGAN total_hutang
        await _supabase
            .rpc(
              'increment_field',
              params: {
                'table_name': 'PELANGGAN',
                'row_id': _selectedCustomerId,
                'field_name': 'total_hutang',
                'increment_value': sisaHutang,
              },
            )
            .onError((error, stackTrace) {
              // Fallback: manual update if RPC not available
              debugPrint(
                'RPC not available, skipping PELANGGAN update: $error',
              );
              return null;
            });
      }

      // 4. Decrement stock for each product
      for (var p in _cartProducts) {
        final pid = p['id'] as String;
        final qty = _cart[pid] ?? 0;
        final currentStock = num.parse((p['stok_saat_ini'] ?? 0).toString());
        final newStock = (currentStock - qty).clamp(0, double.infinity);

        await _supabase
            .from('PRODUK')
            .update({
              'stok_saat_ini': newStock,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', pid);
      }

      final cashReceived = _paymentMethod == 'TUNAI'
          ? _netTotal.toDouble()
          : dp.toDouble();

      // 5. Update kas based on money actually received right now.
      // Kasbon/hutang should only add DP, not the full invoice amount.
      if (cashReceived > 0) {
        _cache.uangKas += cashReceived;
      }

      // Refresh product cache
      await _cache.refreshProducts();

      // 6. Persist updated uang_kas to WARUNG table
      await _supabase
          .from('WARUNG')
          .update({
            'uang_kas': _cache.uangKas,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', warungId);

      await _insertBukuKasPenjualan(
        warungId: warungId,
        penjualanId: penjualanId as String,
        tanggal: timestamp,
        amount: cashReceived,
        invoiceNo: invoiceNo,
        keterangan: _paymentMethod == 'TUNAI'
            ? 'Penjualan tunai'
            : dp > 0
            ? 'DP kasbon'
            : 'Penjualan kasbon tanpa DP',
      );

      if (mounted) {
        AppToast.showSuccess(context, 'Transaksi Berhasil!');

        // Prepare data for Receipt Page
        final receiptData = {
          'penjualan': insertedPenjualan,
          'items': itemsToInsert,
          'payment_method': _paymentMethod,
          'diskon': _discount,
          'net_total': _netTotal,
          'customer_name': _selectedCustomerId != null
              ? _customers.firstWhere(
                  (c) => c['id'] == _selectedCustomerId,
                  orElse: () => {'nama': '-'},
                )['nama']
              : null,
        };

        context.go('/transaksi/receipt', extra: receiptData);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Gagal memproses transaksi: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _jatuhTempo ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _jatuhTempo) {
      setState(() {
        _jatuhTempo = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                children: [
                  _buildSectionTitle('Keranjang Belanja'),
                  const SizedBox(height: 12),
                  _buildCartList(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Ringkasan Biaya'),
                  const SizedBox(height: 12),
                  _buildSummary(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Tipe Pembayaran'),
                  const SizedBox(height: 12),
                  _buildPaymentSelection(),
                  const SizedBox(height: 16),

                  // Dynamic Payment Form
                  if (_paymentMethod == 'TUNAI')
                    _buildTunaiForm()
                  else
                    _buildHutangForm(),

                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop(_cart);
                  } else {
                    context.go('/transaksi/pos');
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pembayaran',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCartList() {
    if (_cartProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        ),
        child: const Center(
          child: Text(
            'Keranjang belanja kosong',
            style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._cartProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final pid = product['id'] as String;
            final qty = _cart[pid] ?? 0;
            final price = num.parse((product['harga_jual'] ?? 0).toString());
            final stock = num.parse((product['stok_saat_ini'] ?? 0).toString()).toInt();
            final isAddDisabled = stock <= 0 || qty >= stock;

            String iconName = 'Lainya.png';
            if (product['KATEGORI_PRODUK'] != null) {
              iconName =
                  (product['KATEGORI_PRODUK'] as Map<String, dynamic>?)?['icon']
                      as String? ??
                  'Lainya.png';
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        _resolveIconPath(iconName),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product['nama_produk']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatter.format(price * qty),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '(${_formatter.format(price)}/pcs)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _updateQty(pid, -1),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _updateQty(pid, 1),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isAddDisabled
                                            ? Colors.grey[300]
                                            : AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: isAddDisabled
                                            ? Colors.black45
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < _cartProducts.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.grey[200], thickness: 1),
                  ),
              ],
            );
          }),
          const SizedBox(height: 16),
          // Add More Product Button
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                context.pop(_cart);
              } else {
                context.go('/transaksi/pos');
              }
            }, // Go back to POS
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppTheme.primary, size: 20),
                SizedBox(width: 4),
                Text(
                  'Tambah Produk Lainnya',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _formatter.format(_totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diskon',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(
                width: 140,
                height: 44,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    prefixText: '- Rp ',
                    prefixStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD1EDD8),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD1EDD8),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _formatter.format(_netTotal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _paymentMethod = 'TUNAI'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _paymentMethod == 'TUNAI'
                    ? AppTheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _paymentMethod == 'TUNAI'
                      ? AppTheme.primary
                      : const Color(0xFFD1EDD8),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'TUNAI',
                  style: TextStyle(
                    color: _paymentMethod == 'TUNAI'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _paymentMethod = 'HUTANG'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _paymentMethod == 'HUTANG'
                    ? const Color(0xFFF8BD00)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _paymentMethod == 'HUTANG'
                      ? const Color(0xFFF8BD00)
                      : const Color(0xFFD1EDD8),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'KASBON (Hutang)',
                  style: TextStyle(
                    color: _paymentMethod == 'HUTANG'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTunaiForm() {
    final uangStr = _uangDiterimaController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final uang = num.tryParse(uangStr) ?? 0;

    final sisa = _netTotal - uang;
    final isKurang = sisa > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uang Diterima',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _uangDiterimaController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              prefixText: 'Rp  ',
              prefixStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD1EDD8),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD1EDD8),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isKurang ? 'Kurang' : 'Kembalian',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _formatter.format(sisa.abs()),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isKurang ? Colors.red : AppTheme.primary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredCustomers = _customers
                .where((c) {
                  final name = (c['nama'] as String).toLowerCase();
                  return name.contains(searchQuery.toLowerCase());
                })
                .take(5)
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Pilih Pelanggan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari pelanggan...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1EDD8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1EDD8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredCustomers.isEmpty
                            ? const Center(
                                child: Text(
                                  'Pelanggan tidak ditemukan.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer = filteredCustomers[index];
                                  final name = customer['nama'] as String;
                                  return Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.primary
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing:
                                            _selectedCustomerId ==
                                                customer['id']
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: AppTheme.primary,
                                              )
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedCustomerId =
                                                customer['id'] as String;
                                          });
                                          Navigator.pop(ctx);
                                        },
                                      ),
                                      if (index < filteredCustomers.length - 1)
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFE5E7EB),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const Divider(color: Color(0xFFE5E7EB)),
                      ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Tambah Pelanggan Baru',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await context.push('/pelanggan/add');
                          _fetchCustomers();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHutangForm() {
    final dpStr = _uangMukaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final dp = num.tryParse(dpStr) ?? 0;
    final sisaHutang = _netTotal - dp;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector Pelanggan
          const Text(
            'Pilih Pelanggan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showCustomerPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedCustomerId != null
                          ? (_customers.firstWhere(
                                  (c) => c['id'] == _selectedCustomerId,
                                  orElse: () => {
                                    'nama': 'Pelanggan tidak ditemukan',
                                  },
                                )['nama']
                                as String)
                          : 'Pilih nama pelanggan...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: _selectedCustomerId != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedCustomerId != null
                            ? Colors.black87
                            : const Color(0xFF9CA3AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Uang Muka (DP)
          const Text(
            'Uang Muka (DP) - Opsional',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _uangMukaController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              prefixText: 'Rp  ',
              prefixStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD1EDD8),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD1EDD8),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFF8BD00),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Sisa Hutang Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sisa Hutang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _formatter.format(sisaHutang),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8BD00), // Hutang uses Yellow Theme
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Jatuh Tempo
          const Text(
            'Jatuh Tempo (Opsional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _jatuhTempo != null
                        ? DateFormat(
                            'dd MMM yyyy',
                            'id_ID',
                          ).format(_jatuhTempo!)
                        : 'Pilih tanggal...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _jatuhTempo != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  _jatuhTempo != null
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _jatuhTempo = null;
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        )
                      : const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        32,
      ), // High bottom padding for safe area
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'BAYAR SEKARANG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
