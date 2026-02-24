import 'dart:math';

import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';

class InsertProductPage extends StatefulWidget {
  const InsertProductPage({super.key});

  @override
  State<InsertProductPage> createState() => _InsertProductPageState();
}

class _InsertProductPageState extends State<InsertProductPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

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
  String? _warungId;
  late String _kodeProduk;

  /// Valid icon filenames in assets/icon/produk-icon/
  static const Set<String> _validIcons = {
    'BumbuDapur.png', 'Cemilan.png', 'Lainya.png', 'Minuman.png',
    'Obat.png', 'PerlengkapanMandi.png', 'Rokok.png', 'Sembako.png',
  };

  /// Resolve icon path — validates against known assets, fallback to Lainya
  String _resolveIconPath(String? iconName) {
    if (iconName == null || iconName.isEmpty || !_validIcons.contains(iconName)) {
      return 'assets/icon/produk-icon/Lainya.png';
    }
    return 'assets/icon/produk-icon/$iconName';
  }

  String get _currentIcon => _resolveIconPath(_selectedKategoriIcon);

  @override
  void initState() {
    super.initState();
    _kodeProduk = _generateKodeProduk();
    _initData();
    _hargaModalController.addListener(_calculateMargin);
    _hargaJualController.addListener(_calculateMargin);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaModalController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  /// Generate kode produk random — format: 1 huruf prefix + 12 karakter alfanumerik
  /// Mirip format barcode EAN-13 (13 digit) yang umum di produk makanan retail
  String _generateKodeProduk() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final code =
        List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'U$code';
  }

  double _margin = 0;
  void _calculateMargin() {
    final beli = double.tryParse(
            _hargaModalController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
    final jual = double.tryParse(
            _hargaJualController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
    setState(() => _margin = jual - beli);
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return;

      final userData = await supabase
          .from('WARUNG')
          .select('id')
          .eq('user_id', userId)
          .single();

      _warungId = userData['id'];

      // Sync master data
      await _syncMasterCategories(_warungId!);
      await _syncMasterSatuan(_warungId!);

      final catData = await supabase
          .from('KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order')
          .eq('warung_id', _warungId!)
          .order('sort_order', ascending: true);

      final satuanData = await supabase
          .from('SATUAN_PRODUK')
          .select('id, nama_satuan, sort_order, master_satuan_id')
          .eq('warung_id', _warungId!)
          .order('sort_order', ascending: true);

      setState(() {
        _categories = List<Map<String, dynamic>>.from(catData);
        _satuanItems = List<Map<String, dynamic>>.from(satuanData);
      });
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sync master categories by ID reference — handles add, edit, and delete
  Future<void> _syncMasterCategories(String warungId) async {
    try {
      // Get ALL master categories (active + inactive)
      final allMasterData = await supabase
          .from('MASTER_KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order, is_active');

      // Get user's existing categories (with master reference)
      final userData = await supabase
          .from('KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order, master_kategori_id')
          .eq('warung_id', warungId);

      final userByMasterId = <String, Map<String, dynamic>>{};
      for (final u in (userData as List)) {
        final mid = u['master_kategori_id']?.toString();
        if (mid != null) userByMasterId[mid] = u;
      }

      for (final master in (allMasterData as List)) {
        final masterId = master['id'].toString();
        final isActive = master['is_active'] == true;
        final existing = userByMasterId[masterId];

        if (isActive) {
          if (existing == null) {
            // ADD: new master category not yet in user's list
            await supabase.from('KATEGORI_PRODUK').insert({
              'warung_id': warungId,
              'nama_kategori': master['nama_kategori'],
              'icon': master['icon'],
              'sort_order': master['sort_order'] ?? 0,
              'master_kategori_id': masterId,
            });
          } else {
            // UPDATE: master was edited (name or icon changed)
            if (existing['nama_kategori'] != master['nama_kategori'] ||
                existing['icon'] != master['icon']) {
              await supabase.from('KATEGORI_PRODUK').update({
                'nama_kategori': master['nama_kategori'],
                'icon': master['icon'],
                'sort_order': master['sort_order'] ?? 0,
              }).eq('id', existing['id']);
            }
          }
        } else {
          // DELETE: master was deactivated → remove from user
          if (existing != null) {
            await supabase
                .from('KATEGORI_PRODUK')
                .delete()
                .eq('id', existing['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing master categories: $e');
    }
  }

  /// Sync master satuan by ID reference — handles add, edit, and delete
  Future<void> _syncMasterSatuan(String warungId) async {
    try {
      final allMasterData = await supabase
          .from('MASTER_SATUAN')
          .select('id, nama_satuan, sort_order, is_active');

      final userData = await supabase
          .from('SATUAN_PRODUK')
          .select('id, nama_satuan, sort_order, master_satuan_id')
          .eq('warung_id', warungId);

      final userByMasterId = <String, Map<String, dynamic>>{};
      for (final u in (userData as List)) {
        final mid = u['master_satuan_id']?.toString();
        if (mid != null) userByMasterId[mid] = u;
      }

      for (final master in (allMasterData as List)) {
        final masterId = master['id'].toString();
        final isActive = master['is_active'] == true;
        final existing = userByMasterId[masterId];

        if (isActive) {
          if (existing == null) {
            await supabase.from('SATUAN_PRODUK').insert({
              'warung_id': warungId,
              'nama_satuan': master['nama_satuan'],
              'sort_order': master['sort_order'] ?? 0,
              'master_satuan_id': masterId,
            });
          } else {
            if (existing['nama_satuan'] != master['nama_satuan']) {
              await supabase.from('SATUAN_PRODUK').update({
                'nama_satuan': master['nama_satuan'],
                'sort_order': master['sort_order'] ?? 0,
              }).eq('id', existing['id']);
            }
          }
        } else {
          if (existing != null) {
            await supabase
                .from('SATUAN_PRODUK')
                .delete()
                .eq('id', existing['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing master satuan: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_warungId == null) return;

    setState(() => _isLoading = true);
    try {
      final productData = {
        'warung_id': _warungId,
        'kategori_id': _selectedKategoriId,
        'nama_produk': _namaController.text,
        'barcode': _kodeProduk,
        'harga_modal': double.tryParse(
                _hargaModalController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0,
        'harga_jual': double.tryParse(
                _hargaJualController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0,
        'stok_saat_ini':
            _tanpaStok ? 0 : (int.tryParse(_stokController.text) ?? 0),
        'satuan': _selectedSatuan,
        'is_active': true,
      };

      await supabase.from('PRODUK').insert(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan'),
            backgroundColor: Color(0xFF13B158),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading && _warungId == null
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

  // ==================== HEADER ====================

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
                  'Tambah Produk',
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
                    child: const Icon(Icons.close, color: Colors.black,
                        size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOP CONTAINER ====================

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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Kode Produk Row ---
          _buildKodeProdukRow(),
          const SizedBox(height: 20),

          // --- Nama Produk ---
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
                color: const Color(0xFF6B7280).withOpacity(0.8),
                fontFamily: 'Poppins',
              ),
              decoration: _inputDecoration('INPUT NAMA PRODUK...'),
            ),
          ),
          const SizedBox(height: 16),

          // --- Kategori ---
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
                          color: const Color(0xFFD1EDD8), width: 1.5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedKategoriName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: const Color(0xFF6B7280).withOpacity(0.8),
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
                        color: const Color(0xFFD1EDD8), width: 1.5),
                  ),
                  child: const Icon(Icons.format_list_bulleted,
                      color: Color(0xFFF8BD00), size: 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Satuan ---
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
                          color: const Color(0xFFD1EDD8), width: 1.5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedSatuan ?? 'INPUT SATUAN...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: _selectedSatuan != null
                            ? const Color(0xFF6B7280).withOpacity(0.8)
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
                        color: const Color(0xFFD1EDD8), width: 1.5),
                  ),
                  child: const Icon(Icons.format_list_bulleted,
                      color: Color(0xFFF8BD00), size: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== KODE PRODUK ROW ====================

  Widget _buildKodeProdukRow() {
    return Row(
      children: [
        // Icon container 90x90
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EDD8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
        // Kode Produk text
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
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8BD00),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        // Edit icon 48x48
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

  // ==================== STOK & HARGA CARD ====================

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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stok header row
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
                          color: Color(0xFF6B7280), width: 1.5),
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
          SizedBox(
            height: 60,
            child: TextFormField(
              controller: _stokController,
              enabled: !_tanpaStok,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280).withOpacity(0.8),
                fontFamily: 'Poppins',
              ),
              decoration: _inputDecoration(''),
            ),
          ),
          const SizedBox(height: 16),

          // Harga row
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
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib' : null,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280).withOpacity(0.8),
                          fontFamily: 'Poppins',
                        ),
                        decoration: _inputDecoration(''),
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
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib' : null,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280).withOpacity(0.8),
                          fontFamily: 'Poppins',
                        ),
                        decoration: _inputDecoration(''),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Margin
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Margin Keuntungan untuk produk ini sebesar',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Rp ${_margin.abs().toStringAsFixed(0)},-',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SAVE BUTTON ====================

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

  // ==================== SHARED INPUT DECORATION ====================

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF6B7280).withOpacity(0.5),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

  // ==================== DIALOGS ====================

  void _showEditKodeDialog() {
    showModalBottomSheet(
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
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Title with icon
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8BD00).withOpacity(0.15),
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
              // Option 1: Edit Manual
              _buildOptionTile(
                onTap: () {
                  Navigator.pop(ctx);
                  _showManualEditKode();
                },
                icon: Icons.edit_rounded,
                iconBg: AppTheme.primary.withOpacity(0.1),
                iconColor: AppTheme.primary,
                title: 'Edit Manual',
                subtitle: 'Ketik kode produk sendiri',
              ),
              const SizedBox(height: 12),
              // Option 2: Scan Barcode
              _buildOptionTile(
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur scan barcode segera hadir')),
                  );
                },
                icon: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFFF8BD00).withOpacity(0.1),
                iconColor: const Color(0xFFF8BD00),
                title: 'Scan Barcode',
                subtitle: 'Scan kode barcode produk',
              ),
              const SizedBox(height: 12),
              // Option 3: Generate Baru
              _buildOptionTile(
                onTap: () {
                  setState(() => _kodeProduk = _generateKodeProduk());
                  Navigator.pop(ctx);
                },
                icon: Icons.refresh_rounded,
                iconBg: Colors.blue.withOpacity(0.1),
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
    showModalBottomSheet(
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
                // Drag handle
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
                // Input
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
                // Buttons
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
                              setState(() => _kodeProduk = controller.text.trim());
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
    showModalBottomSheet(
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
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 16),
                  // Scrollable list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Lainnya (default)
                        ListTile(
                          leading: Image.asset(
                            'assets/icon/produk-icon/Lainya.png',
                            width: 32,
                            height: 32,
                          ),
                          title: const Text('Lainnya',
                              style: TextStyle(fontFamily: 'Poppins')),
                          trailing: _selectedKategoriId == null
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.primary)
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
                            leading:
                                Image.asset(iconPath, width: 32, height: 32),
                            title: Text(catName,
                                style:
                                    const TextStyle(fontFamily: 'Poppins')),
                            trailing: _selectedKategoriId == cat['id']
                                ? const Icon(Icons.check_circle,
                                    color: AppTheme.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedKategoriId = cat['id'];
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
                  // Tambah Kategori button
                  const Divider(),
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          color: AppTheme.primary, size: 20),
                    ),
                    title: const Text('Tambah Kategori',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddKategoriDialog();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddKategoriDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
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
                // Drag handle
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
                // Title row with icon
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Kategori',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'Kategori baru akan menggunakan icon default',
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
                const SizedBox(height: 20),
                // Input
                SizedBox(
                  height: 56,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    decoration: _inputDecoration('Nama kategori baru'),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
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
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isEmpty || _warungId == null) return;

                            try {
                              final result =
                                  await supabase.from('KATEGORI_PRODUK').insert({
                                'warung_id': _warungId,
                                'nama_kategori': name,
                                'icon': 'Lainya.png',
                                'sort_order': _categories.length,
                              }).select().single();

                              setState(() {
                                _categories.add(result);
                                _selectedKategoriId = result['id'];
                                _selectedKategoriName = name;
                                _selectedKategoriIcon = 'Lainya.png';
                              });

                              if (mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
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

  void _showSatuanPicker() {
    showModalBottomSheet(
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
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 16),
                  // Scrollable list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ..._satuanItems.map((sat) {
                          final name = sat['nama_satuan'].toString();
                          return ListTile(
                            title: Text(name,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500)),
                            trailing: _selectedSatuanId == sat['id']
                                ? const Icon(Icons.check_circle,
                                    color: AppTheme.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedSatuanId = sat['id'];
                                _selectedSatuan = name;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  // Tambah Satuan button
                  const Divider(),
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          color: AppTheme.primary, size: 20),
                    ),
                    title: const Text('Tambah Satuan',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddSatuanDialog();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSatuanDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
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
                // Drag handle
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
                // Title row with icon
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Satuan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'Satuan baru untuk produk Anda',
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
                const SizedBox(height: 20),
                // Input
                SizedBox(
                  height: 56,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    decoration: _inputDecoration('Contoh: BOTOL'),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
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
                          onPressed: () async {
                            final name = controller.text.trim().toUpperCase();
                            if (name.isEmpty || _warungId == null) return;

                            try {
                              final result =
                                  await supabase.from('SATUAN_PRODUK').insert({
                                'warung_id': _warungId,
                                'nama_satuan': name,
                                'sort_order': _satuanItems.length,
                              }).select().single();

                              setState(() {
                                _satuanItems.add(result);
                                _selectedSatuanId = result['id'];
                                _selectedSatuan = name;
                              });

                              if (mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
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
}

