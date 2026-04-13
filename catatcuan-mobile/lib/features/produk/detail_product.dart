import 'dart:math';

import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/utils/currency_formatter.dart';
import 'package:catatcuan_mobile/core/utils/product_stock_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';

class DetailProductPage extends StatefulWidget {
  const DetailProductPage({super.key, required this.product});
  final Map<String, dynamic> product;

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaModalController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  String? _selectedKategoriId;
  String _selectedKategoriName = 'Lainnya';
  String _selectedKategoriIcon = 'Lainya.png';
  String? _selectedSatuanId;
  String? _selectedSatuan;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _satuanItems = [];
  bool _isLoading = false;
  bool _tanpaStok = false;

  late String _kodeProduk;

  void _closePage() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(Duration.zero, () {
      if (mounted && Navigator.of(context).canPop()) {
        context.pop();
      }
    });
  }

  static const Set<String> _validIcons = {
    'BumbuDapur.png',
    'Cemilan.png',
    'Lainya.png',
    'Minuman.png',
    'Obat.png',
    'PerlengkapanMandi.png',
    'Rokok.png',
    'Sembako.png',
  };

  String _resolveIconPath(String? iconName) {
    if (iconName == null ||
        iconName.isEmpty ||
        !_validIcons.contains(iconName)) {
      return 'assets/icon/produk-icon/Lainya.png';
    }
    return 'assets/icon/produk-icon/$iconName';
  }

  String get _currentIcon => _resolveIconPath(_selectedKategoriIcon);

  @override
  void initState() {
    super.initState();
    _kodeProduk =
        (widget.product['barcode'] as String?) ?? _generateKodeProduk();
    _namaController.text = widget.product['nama_produk']?.toString() ?? '';
    _hargaModalController.text = formatIdrNumber(
      num.parse((widget.product['harga_modal'] ?? 0).toString()).toInt(),
    );
    _hargaJualController.text = formatIdrNumber(
      num.parse((widget.product['harga_jual'] ?? 0).toString()).toInt(),
    );

    final stok = ProductStockHelper.parseStock(widget.product['stok_saat_ini']);
    _tanpaStok = ProductStockHelper.isUnlimited(stok);
    _stokController.text = _tanpaStok ? '' : stok.toString();

    _selectedKategoriId = widget.product['kategori_id'] as String?;
    _selectedSatuan = widget.product['satuan'] as String?;

    if (widget.product['KATEGORI_PRODUK'] != null) {
      final kategori =
          widget.product['KATEGORI_PRODUK'] as Map<String, dynamic>;
      _selectedKategoriName =
          (kategori['nama_kategori'] as String?) ?? 'Lainnya';
      _selectedKategoriIcon = (kategori['icon'] as String?) ?? 'Lainya.png';
    }

    _loadFromCache();
    _hargaModalController.addListener(_calculateMargin);
    _hargaJualController.addListener(_calculateMargin);
    _calculateMargin();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaModalController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  String _generateKodeProduk() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final code = List.generate(
      12,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return 'U$code';
  }

  double _margin = 0;
  void _calculateMargin() {
    final beli =
        double.tryParse(
          _hargaModalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final jual =
        double.tryParse(
          _hargaJualController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    setState(() => _margin = jual - beli);
  }

  /// Load data from cache — instant, no network call, no loading spinner.
  void _loadFromCache() {
    _categories = List<Map<String, dynamic>>.from(_cache.categories);
    _satuanItems = List<Map<String, dynamic>>.from(_cache.satuanItems);
  }

  Future<bool> _isBarcodeAlreadyUsedByOtherProduct(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return false;

    final existing = await supabase
        .from('PRODUK')
        .select('id')
        .eq('warung_id', widget.product['warung_id'] as Object)
        .eq('barcode', normalized)
        .neq('id', widget.product['id'] as Object)
        .limit(1)
        .maybeSingle();

    return existing != null;
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Produk',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus produk ini?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFEF4444,
                    ), // Tailwind Red 500
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _archiveProduct();
        if (mounted) {
          AppToast.showSuccess(context, 'Produk berhasil dihapus');
          context.pop(true);
        }
      } catch (e) {
        debugPrint('Error deleting product: $e');
        if (mounted) {
          AppToast.showError(context, 'Gagal menghapus produk: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _archiveProduct() async {
    final payload = {
      'is_active': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await supabase
          .from('PRODUK')
          .update(payload)
          .eq('id', widget.product['id'] as Object);
    } catch (e) {
      final message = e.toString().toLowerCase();
      final isLegacyDeleteError =
          message.contains('penjualan_item_produk_id_fkey') ||
          message.contains('violates foreign key constraint');
      if (!isLegacyDeleteError) rethrow;

      await supabase
          .from('PRODUK')
          .update(payload)
          .eq('id', widget.product['id'] as Object);
    }

    await _cache.refreshProducts();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (await _isBarcodeAlreadyUsedByOtherProduct(_kodeProduk)) {
        if (mounted) {
          AppToast.showWarning(context, 'Barcode sudah dipakai produk lain.');
        }
        return;
      }

      final productData = {
        'kategori_id': _selectedKategoriId,
        'nama_produk': _namaController.text,
        'barcode': _kodeProduk,
        'harga_modal':
            double.tryParse(
              _hargaModalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'harga_jual':
            double.tryParse(
              _hargaJualController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'stok_saat_ini': _tanpaStok
            ? ProductStockHelper.unlimitedStockValue
            : (int.tryParse(_stokController.text) ?? 0),
        'satuan': _selectedSatuan,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await supabase
          .from('PRODUK')
          .update(productData)
          .eq('id', widget.product['id'] as Object);

      if (mounted) {
        AppToast.showSuccess(context, 'Produk berhasil diperbarui');
        context.pop(true);
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        AppToast.showError(context, 'Gagal menyimpan produk: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _tambahStok() {
    final int current = int.tryParse(_stokController.text) ?? 0;
    setState(() {
      _stokController.text = (current + 1).toString();
      _tanpaStok = false;
    });
  }

  void _kurangStok() {
    final int current = int.tryParse(_stokController.text) ?? 0;
    if (current > 0) {
      setState(() {
        _stokController.text = (current - 1).toString();
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
              child: _isLoading && _categories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            _buildTopContainer(),
                            const SizedBox(height: 16),
                            _buildStokHargaCard(),
                            const SizedBox(height: 24),
                            _buildSaveButton(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
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
                  'Detail Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _deleteProduct(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.9),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _closePage,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 500,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKodeProdukRow(),
          const SizedBox(height: 20),

          const Text(
            'Nama Produk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: TextFormField(
              controller: _namaController,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama produk wajib diisi' : null,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                fontFamily: 'Poppins',
              ),
              decoration: _inputDecoration('INPUT NAMA PRODUK...'),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showKategoriPicker,
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD1EDD8),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedKategoriName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showKategoriPicker,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD1EDD8),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.format_list_bulleted,
                    color: Color(0xFFF8BD00),
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Satuan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showSatuanPicker,
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD1EDD8),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedSatuan ?? 'INPUT SATUAN...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: _selectedSatuan != null
                            ? const Color(0xFF6B7280).withValues(alpha: 0.8)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showSatuanPicker,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD1EDD8),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.format_list_bulleted,
                    color: Color(0xFFF8BD00),
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKodeProdukRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EDD8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              _currentIcon,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kode Produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _kodeProduk,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8BD00),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showEditKodeDialog,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(
              'assets/icon/produk-icon/edit.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStokHargaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stok Saat Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Tanpa Stok',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _tanpaStok,
                      onChanged: (v) {
                        setState(() {
                          _tanpaStok = v ?? false;
                          if (_tanpaStok) _stokController.clear();
                        });
                      },
                      activeColor: AppTheme.primary,
                      side: const BorderSide(
                        color: Color(0xFF6B7280),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _tanpaStok ? null : _kurangStok,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD1EDD8),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: TextFormField(
                    controller: _stokController,
                    enabled: !_tanpaStok,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                      fontFamily: 'Poppins',
                    ),
                    decoration: _inputDecoration(''),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _tanpaStok ? null : _tambahStok,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD1EDD8),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga Beli Satuan (Rp)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: TextFormField(
                        controller: _hargaModalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib' : null,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                          fontFamily: 'Poppins',
                        ),
                        decoration: _inputDecoration('').copyWith(
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFF6B7280,
                            ).withValues(alpha: 0.8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga Jual Satuan (Rp)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: TextFormField(
                        controller: _hargaJualController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib' : null,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                          fontFamily: 'Poppins',
                        ),
                        decoration: _inputDecoration('').copyWith(
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFF6B7280,
                            ).withValues(alpha: 0.8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Margin Keuntungan untuk produk ini sebesar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_margin < 0 ? '-Rp ' : 'Rp '}${formatIdrNumber(_margin.abs().round())},-',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _margin < 0 ? const Color(0xFFDC2626) : AppTheme.primary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF8BD00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'SIMPAN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF6B7280).withValues(alpha: 0.5),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  void _showEditKodeDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8BD00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/icon/produk-icon/edit.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Kode Produk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Pilih cara untuk mengubah kode',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildOptionTile(
                onTap: () {
                  Navigator.pop(ctx);
                  _showManualEditKode();
                },
                icon: Icons.edit_rounded,
                iconBg: AppTheme.primary.withValues(alpha: 0.1),
                iconColor: AppTheme.primary,
                title: 'Edit Manual',
                subtitle: 'Ketik kode produk sendiri',
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                onTap: () {
                  Navigator.pop(ctx);
                  AppToast.showInfo(context, 'Fitur scan barcode segera hadir');
                },
                icon: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFFF8BD00).withValues(alpha: 0.1),
                iconColor: const Color(0xFFF8BD00),
                title: 'Scan Barcode',
                subtitle: 'Scan kode barcode produk',
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                onTap: () {
                  setState(() => _kodeProduk = _generateKodeProduk());
                  Navigator.pop(ctx);
                },
                icon: Icons.refresh_rounded,
                iconBg: Colors.blue.withValues(alpha: 0.1),
                iconColor: Colors.blue,
                title: 'Generate Ulang',
                subtitle: 'Buat kode random baru',
              ),
            ],
          ),
        );
      },
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

  void _showManualEditKode() {
    final controller = TextEditingController(text: _kodeProduk);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Edit Kode Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masukkan kode produk baru',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.5,
                    ),
                    decoration: _inputDecoration('Contoh: U0813GGFN2RT'),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFFD1EDD8)),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              setState(
                                () => _kodeProduk = controller.text.trim(),
                              );
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKategoriPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
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
                    'Pilih Kategori',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ListTile(
                          leading: Image.asset(
                            'assets/icon/produk-icon/Lainya.png',
                            width: 32,
                            height: 32,
                          ),
                          title: const Text(
                            'Lainnya',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          trailing: _selectedKategoriId == null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedKategoriId = null;
                              _selectedKategoriName = 'Lainnya';
                              _selectedKategoriIcon = 'Lainya.png';
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        if (_categories.isNotEmpty) const Divider(),
                        ..._categories.map((cat) {
                          final catName = cat['nama_kategori'].toString();
                          final iconFile =
                              cat['icon']?.toString() ?? 'Lainya.png';
                          final iconPath = _resolveIconPath(iconFile);
                          return ListTile(
                            leading: Image.asset(
                              iconPath,
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              catName,
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            trailing: _selectedKategoriId == cat['id']
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedKategoriId = cat['id'] as String?;
                                _selectedKategoriName = catName;
                                _selectedKategoriIcon = iconFile;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSatuanPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
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
                    'Pilih Satuan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ..._satuanItems.map((sat) {
                          final name = sat['nama_satuan'].toString();
                          return ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: _selectedSatuanId == sat['id']
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedSatuanId = sat['id'] as String?;
                                _selectedSatuan = name;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
