import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InsertPengeluaranPage extends StatefulWidget {
  const InsertPengeluaranPage({super.key});

  @override
  State<InsertPengeluaranPage> createState() => _InsertPengeluaranPageState();
}

class _InsertPengeluaranPageState extends State<InsertPengeluaranPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;

  final TextEditingController _tanggalController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();

  Map<String, dynamic>? _selectedCategory;
  bool _isLoading = false;
  String? _warungId;
  String _sumberKas = 'warung'; // 'warung' or 'operasional'

  static const Set<String> _validIcons = {
    'Kesehatan.png',
    'LainnyaPribadi.png',
    'MakanDapur.png',
    'Pakaian.png',
    'Pendidikan.png',
    'Sedekah.png',
  };

  @override
  void initState() {
    super.initState();
    _warungId = _cache.warungId;
    if (_cache.expenseCategories.isNotEmpty) {
      _selectedCategory = _cache.expenseCategories.first;
    }
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _catatanController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  String _resolveIconPath(String? iconName) {
    if (iconName == null ||
        iconName.isEmpty ||
        !_validIcons.contains(iconName)) {
      return 'assets/icon/pengeluaran-icon/LainnyaPribadi.png';
    }
    return 'assets/icon/pengeluaran-icon/$iconName';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (_selectedCategory == null) {
      AppToast.showWarning(context, 'Pilih kategori pengeluaran dulu');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final double amount = double.parse(
          _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );

        // 1. Insert PENGELUARAN
        await _supabase.from('PENGELUARAN').insert({
          'warung_id': _warungId,
          'kategori_id': _selectedCategory!['id'],
          'tanggal': _selectedDate.toIso8601String(),
          'amount': amount,
          'keterangan':
              '[Sumber: ${_sumberKas.toUpperCase()}] ${_catatanController.text.trim()}',
        });

        // 2. Update WARUNG balances
        final Map<String, dynamic> updateData = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_sumberKas == 'warung') {
          _cache.uangKas -= amount;
          updateData['uang_kas'] = _cache.uangKas;
        } else {
          _cache.uangKasOperasional -= amount;
          updateData['uang_kas_operasional'] = _cache.uangKasOperasional;
        }

        await _supabase.from('WARUNG').update(updateData).eq('id', _warungId!);

        if (mounted) {
          AppToast.showSuccess(context, 'Pengeluaran Berhasil Dicatat');
          context.pop(true);
        }
      } catch (e) {
        debugPrint('Error saving expense: $e');
        if (mounted) {
          AppToast.showError(context, 'Gagal mencatat pengeluaran: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildTopCard(),
                      const SizedBox(height: 16),
                      _buildSecondaryCard(),
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
                  'Catat Pengeluaran',
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
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1EDD8)),
                ),
                child: Center(
                  child: Image.asset(
                    _resolveIconPath(_selectedCategory?['icon'] as String?),
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
                    _buildFieldLabel('Tanggal Transaksi'),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Text(
                        _tanggalController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF8BD00),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('Kategori Pengeluaran'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showCategoryPicker,
            child: Row(
              children: [
                Expanded(
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
                      (_selectedCategory?['nama_kategori'] as String?) ??
                          'PILIH KATEGORI...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: _selectedCategory != null
                            ? const Color(0xFF6B7280).withValues(alpha: 0.8)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Catatan'),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: TextFormField(
              controller: _catatanController,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                fontFamily: 'Poppins',
              ),
              decoration: _inputDecoration('TAMBAH CATATAN...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard() {
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
          _buildFieldLabel('Diambil Dari'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSourceChip(
                  'warung',
                  'UANG WARUNG',
                  _cache.uangKas,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSourceChip(
                  'operasional',
                  'KAS OPR',
                  _cache.uangKasOperasional,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Jumlah (Rp)'),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: TextFormField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
                fontFamily: 'Poppins',
              ),
              decoration: _inputDecoration('0'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final val =
                    double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                if (val <= 0) return 'Harus > 0';
                final double balance = _sumberKas == 'warung'
                    ? _cache.uangKas
                    : _cache.uangKasOperasional;
                if (val > balance) return 'Saldo tidak cukup';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String value, String label, double bal) {
    final bool isSel = _sumberKas == value;
    return GestureDetector(
      onTap: () => setState(() => _sumberKas = value),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSel
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? AppTheme.primary : const Color(0xFFD1EDD8),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSel ? AppTheme.primary : Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp',
                decimalDigits: 0,
              ).format(bal),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSel ? AppTheme.primary : Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF8BD00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        fontFamily: 'Poppins',
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
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _cache.expenseCategories.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.withValues(alpha: 0.1),
                        thickness: 1,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _cache.expenseCategories[index];
                        final isSelected = _selectedCategory?['id'] == cat['id'];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: Image.asset(
                            _resolveIconPath(cat['icon'] as String?),
                            width: 32,
                            height: 32,
                          ),
                          title: Text(
                            cat['nama_kategori'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : Colors.black87,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                      'Tambah Kategori',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddCategoryDialog();
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

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    String tipe = 'business';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      'Tambah Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('BISNIS')),
                            selected: tipe == 'business',
                            onSelected: (v) =>
                                setModalState(() => tipe = 'business'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('PRIBADI')),
                            selected: tipe == 'personal',
                            onSelected: (v) =>
                                setModalState(() => tipe = 'personal'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: _inputDecoration('Nama kategori'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty || _warungId == null) return;
                          try {
                            final res = await _supabase
                                .from('KATEGORI_PENGELUARAN')
                                .insert({
                                  'warung_id': _warungId,
                                  'nama_kategori': name,
                                  'tipe': tipe,
                                  'icon': 'LainnyaPribadi.png',
                                })
                                .select()
                                .single();
                            setState(() {
                              _cache.expenseCategories.add(res);
                              _selectedCategory = res;
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }
                            AppToast.showError(this.context, 'Gagal: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'SIMPAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
