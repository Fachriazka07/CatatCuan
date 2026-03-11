import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/hutang_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InsertHutangPage extends StatefulWidget {
  const InsertHutangPage({super.key});

  @override
  State<InsertHutangPage> createState() => _InsertHutangPageState();
}

class _InsertHutangPageState extends State<InsertHutangPage> {
  final _hutangService = HutangService();
  final _cache = DataCacheService.instance;

  DateTime _selectedDate = DateTime.now();
  String _jenis = 'HUTANG'; // 'HUTANG' or 'PIUTANG'
  
  Map<String, dynamic>? _selectedCustomer;
  final _catatanController = TextEditingController();
  final _nilaiController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveHutang() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih pelanggan terlebih dahulu')));
      return;
    }
    
    final nilai = double.tryParse(_nilaiController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (nilai == null || nilai <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai harus lebih dari 0')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hutangData = {
        'warung_id': _cache.warungId,
        'jenis': _jenis,
        'pelanggan_id': _selectedCustomer!['id'],
        'nama_kontak': _selectedCustomer!['nama'] ?? '',
        'catatan': _catatanController.text.trim(),
        'amount_awal': nilai,
        'amount_terbayar': 0,
        'amount_sisa': nilai,
        'status': 'belum_lunas',
        'tanggal_jatuh_tempo': null, 
      };

      await _hutangService.addHutang(hutangData);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan!'), backgroundColor: AppTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCustomerPicker() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> customers = [];
    bool isSearching = false;

    // Initial fetch
    Future<List<Map<String, dynamic>>> fetchCustomers(String query) async {
      final warungId = _cache.warungId;
      if (warungId == null) return [];
      var q = Supabase.instance.client
          .from('PELANGGAN')
          .select()
          .eq('warung_id', warungId);
      if (query.isNotEmpty) {
        q = q.ilike('nama', '%$query%');
      }
      final res = await q.order('nama', ascending: true).limit(20);
      return List<Map<String, dynamic>>.from(res);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Load initial data
            if (customers.isEmpty && !isSearching) {
              isSearching = true;
              fetchCustomers('').then((data) {
                setModalState(() {
                  customers = data;
                  isSearching = false;
                });
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pilih Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (val) {
                        setModalState(() => isSearching = true);
                        fetchCustomers(val).then((data) {
                          setModalState(() {
                            customers = data;
                            isSearching = false;
                          });
                        });
                      },
                      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        hintText: 'Cari nama pelanggan...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Poppins'),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2.0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Customer list
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                        : customers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    const Text('Belum ada pelanggan', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 14)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: customers.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                itemBuilder: (_, index) {
                                  final c = customers[index];
                                  final nama = c['nama']?.toString().toUpperCase() ?? 'TANPA NAMA';
                                  final phone = c['phone']?.toString() ?? '';
                                  final isCurrentlySelected = _selectedCustomer?['id'] == c['id'];

                                  return InkWell(
                                    onTap: () {
                                      setState(() => _selectedCustomer = c);
                                      Navigator.pop(ctx);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40, height: 40,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isCurrentlySelected ? const Color(0xFFE6FFE7) : const Color(0xFFF2F6FF),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: isCurrentlySelected ? AppTheme.primary : const Color(0xFFD1EDD8)),
                                            ),
                                            child: Icon(Icons.person, color: isCurrentlySelected ? AppTheme.primary : const Color(0xFF9CA3AF), size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(nama, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: isCurrentlySelected ? AppTheme.primary : const Color(0xFF374151))),
                                                if (phone.isNotEmpty)
                                                  Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Poppins')),
                                              ],
                                            ),
                                          ),
                                          if (isCurrentlySelected)
                                            const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  // Add new customer button
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.person_add, color: AppTheme.primary, size: 20),
                          label: const Text('Tambah Pelanggan Baru', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 15)),
                          onPressed: () async {
                            Navigator.pop(ctx); // Close picker first
                            final result = await context.push('/pelanggan/add');
                            if (result == true) {
                              // Fetch the most recently CREATED customer
                              final warungId = _cache.warungId;
                              if (warungId != null && mounted) {
                                final res = await Supabase.instance.client
                                    .from('PELANGGAN')
                                    .select()
                                    .eq('warung_id', warungId)
                                    .order('created_at', ascending: false)
                                    .limit(1);
                                final newest = List<Map<String, dynamic>>.from(res);
                                if (newest.isNotEmpty) {
                                  setState(() => _selectedCustomer = newest.first);
                                }
                              }
                            }
                          },
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tambah Hutang / Piutang',
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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          _buildFieldLabel('Pilih Jenis Transaksi'),
          const SizedBox(height: 12),
          _buildHutangPiutangSelector(),
          const SizedBox(height: 24),
          _buildFieldLabel('Tanggal Transaksi'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   const Icon(Icons.calendar_today, color: Color(0xFF6B7280), size: 20),
                   const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontFamily: 'Poppins', 
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151)
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          _buildFieldLabel('Pelanggan'),
          const SizedBox(height: 8),
          _buildCustomerSelector(),
          
          const SizedBox(height: 20),
          _buildFieldLabel('Catatan (Opsional)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _catatanController,
            hintText: 'INPUT CATATAN',
          ),
          
          const SizedBox(height: 20),
          _buildFieldLabel('Nilai (Rp)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nilaiController,
            hintText: '0',
            keyboardType: TextInputType.number,
            isAmount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHutangPiutangSelector() {
    return Column(
      children: [
        _buildSelectionItem(
          title: 'SAYA BERHUTANG',
          subtitle: 'Saya meminjam uang ke orang lain',
          icon: Icons.call_received_rounded,
          isSelected: _jenis == 'HUTANG',
          onTap: () => setState(() => _jenis = 'HUTANG'),
        ),
        const SizedBox(height: 12),
        _buildSelectionItem(
          title: 'ORANG BERHUTANG',
          subtitle: 'Orang lain meminjam uang ke saya',
          icon: Icons.call_made_rounded,
          isSelected: _jenis == 'PIUTANG',
          onTap: () => setState(() => _jenis = 'PIUTANG'),
        ),
      ],
    );
  }

  Widget _buildSelectionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6FFE7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: isSelected ? AppTheme.primary : const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: isSelected ? AppTheme.primary.withOpacity(0.8) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    final hasCustomer = _selectedCustomer != null;
    final nama = _selectedCustomer?['nama']?.toString().toUpperCase() ?? '';

    return GestureDetector(
      onTap: _showCustomerPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasCustomer ? AppTheme.primary : const Color(0xFFD1EDD8),
            width: hasCustomer ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasCustomer ? const Color(0xFFE6FFE7) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasCustomer ? AppTheme.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person,
                color: hasCustomer ? Colors.white : const Color(0xFF9CA3AF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasCustomer
                  ? Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins', color: AppTheme.primary,
                      ),
                    )
                  : Text(
                      'Pilih Pelanggan',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: const Color(0xFF6B7280).withValues(alpha: 0.6),
                      ),
                    ),
            ),
            Icon(
              hasCustomer ? Icons.check_circle : Icons.chevron_right,
              color: hasCustomer ? AppTheme.primary : const Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isAmount = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: isAmount ? 20 : 16,
        fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
        color: const Color(0xFF374151),
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: isAmount ? 'Rp ' : null,
        prefixStyle: isAmount ? const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87) : null,
        hintStyle: TextStyle(
          color: const Color(0xFF6B7280).withValues(alpha: 0.6),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8BD00),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _saveHutang,
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                'SIMPAN DATA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
