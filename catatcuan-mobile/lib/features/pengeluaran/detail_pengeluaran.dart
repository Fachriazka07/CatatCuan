import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:catatcuan_mobile/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPengeluaranPage extends StatefulWidget {
  const DetailPengeluaranPage({super.key, required this.expense});
  final Map<String, dynamic> expense;

  @override
  State<DetailPengeluaranPage> createState() => _DetailPengeluaranPageState();
}

class _DetailPengeluaranPageState extends State<DetailPengeluaranPage> {
  final _supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _keteranganController;
  late DateTime _selectedDate;

  String? _selectedKategoriId;
  String _selectedKategoriName = 'Lainnya';
  String _selectedKategoriIcon = 'LainnyaPribadi.png';
  String _selectedSource = 'warung';

  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];

  static const Set<String> _validIcons = {
    'Kesehatan.png',
    'LainnyaPribadi.png',
    'MakanDapur.png',
    'Pakaian.png',
    'Pendidikan.png',
    'Sedekah.png',
  };

  static final RegExp _sourceTagPattern = RegExp(
    r'^\[Sumber:\s*([^\]]+)\]\s*',
    caseSensitive: false,
  );

  void _closePage() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(Duration.zero, () {
      if (mounted && Navigator.of(context).canPop()) {
        context.pop();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final amount = (widget.expense['amount'] as num).toDouble();
    _amountController = TextEditingController(
      text: formatIdrNumber(amount.toInt()),
    );

    final fullKeterangan = widget.expense['keterangan'] as String? ?? '';
    _keteranganController = TextEditingController(
      text: _formatExpenseNote(fullKeterangan),
    );
    _selectedSource = _extractExpenseSource(fullKeterangan);

    _selectedDate = DateTime.parse(widget.expense['tanggal'].toString());
    _selectedKategoriId = widget.expense['kategori_id'] as String?;

    final cat = widget.expense['KATEGORI_PENGELUARAN'] as Map<String, dynamic>?;
    if (cat != null) {
      _selectedKategoriName = cat['nama_kategori'] as String? ?? 'Lainnya';
      _selectedKategoriIcon = cat['icon'] as String? ?? 'LainnyaPribadi.png';
    }

    _categories = List<Map<String, dynamic>>.from(_cache.expenseCategories);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _keteranganController.dispose();
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

  String _extractExpenseSource(String note) {
    final match = _sourceTagPattern.firstMatch(note);
    final sourceLabel = match?.group(1)?.toLowerCase() ?? '';
    return sourceLabel.contains('operasional') ? 'operasional' : 'warung';
  }

  String _formatExpenseNote(String? note) {
    return (note ?? '').replaceFirst(_sourceTagPattern, '').trim();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Pengeluaran',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus pengeluaran ini? Saldo akan dikembalikan.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final double amount = (widget.expense['amount'] as num).toDouble();

        // 1. Update Warung Money (Refund)
        final Map<String, dynamic> updateWarung = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_selectedSource == 'warung') {
          _cache.uangKas += amount;
          updateWarung['uang_kas'] = _cache.uangKas;
        } else {
          _cache.uangKasOperasional += amount;
          updateWarung['uang_kas_operasional'] = _cache.uangKasOperasional;
        }

        await _supabase
            .from('WARUNG')
            .update(updateWarung)
            .eq('id', _cache.warungId!.toString());

        await _supabase
            .from('BUKU_KAS')
            .delete()
            .eq('reference_id', widget.expense['id'] as Object)
            .eq('reference_type', 'PENGELUARAN');

        // 2. Delete Expense
        await _supabase
            .from('PENGELUARAN')
            .delete()
            .eq('id', widget.expense['id'] as Object);

        if (mounted) {
          AppToast.showSuccess(context, 'Pengeluaran berhasil dihapus');
          context.pop(true);
        }
      } catch (e) {
        if (mounted) AppToast.showError(context, 'Gagal menghapus: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final double oldAmount = (widget.expense['amount'] as num).toDouble();
      final double newAmount =
          double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final String oldKeterangan =
          widget.expense['keterangan'] as String? ?? '';
      final String oldSource = _extractExpenseSource(oldKeterangan);
      final String newSource = _selectedSource;
      final expenseTimestamp = _selectedDate.toUtc().toIso8601String();

      // Logic for adjusting money:
      // 1. Refund old amount from old source
      // 2. Deduct new amount from new source

      final Map<String, dynamic> updateWarung = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Refund old
      if (oldSource == 'warung') {
        _cache.uangKas += oldAmount;
      } else {
        _cache.uangKasOperasional += oldAmount;
      }

      // Deduct new
      if (newSource == 'warung') {
        final totalUangWarung = _cache.saldoAwal + _cache.uangKas;
        if (newAmount > totalUangWarung) {
          if (mounted) {
            AppToast.showWarning(context, 'Saldo uang warung tidak cukup');
          }
          return;
        }

        double remaining = newAmount;
        if (_cache.uangKas >= remaining) {
          _cache.uangKas -= remaining;
        } else {
          remaining -= _cache.uangKas;
          _cache.uangKas = 0;
          _cache.saldoAwal = (_cache.saldoAwal - remaining).clamp(
            0,
            double.infinity,
          );
        }
      } else {
        _cache.uangKasOperasional -= newAmount;
      }

      updateWarung['saldo_awal'] = _cache.saldoAwal;
      updateWarung['uang_kas'] = _cache.uangKas;
      updateWarung['uang_kas_operasional'] = _cache.uangKasOperasional;

      // Update Database
      await _supabase
          .from('WARUNG')
          .update(updateWarung)
          .eq('id', _cache.warungId!.toString());

      final sourceTag = newSource == 'operasional'
          ? '[Sumber: Operasional] '
          : '[Sumber: Warung] ';
      final finalKeterangan = '$sourceTag${_keteranganController.text.trim()}';

      await _supabase
          .from('PENGELUARAN')
          .update({
            'kategori_id': _selectedKategoriId,
            'amount': newAmount,
            'keterangan': finalKeterangan,
            'tanggal': expenseTimestamp,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.expense['id'] as Object);

      final saldoSetelah = _cache.saldoAwal + _cache.uangKas;
      final cashBookPayload = {
        'tanggal': expenseTimestamp,
        'tipe': 'keluar',
        'sumber': 'pengeluaran',
        'amount': newAmount,
        'saldo_setelah': saldoSetelah,
        'keterangan': finalKeterangan,
      };

      final existingEntries = await _supabase
          .from('BUKU_KAS')
          .select('id')
          .eq('reference_id', widget.expense['id'] as Object)
          .eq('reference_type', 'PENGELUARAN')
          .limit(1);

      if (existingEntries.isEmpty) {
        await _supabase.from('BUKU_KAS').insert({
          'warung_id': _cache.warungId,
          'reference_id': widget.expense['id'],
          'reference_type': 'PENGELUARAN',
          ...cashBookPayload,
        });
      } else {
        await _supabase
            .from('BUKU_KAS')
            .update(cashBookPayload)
            .eq('id', existingEntries.first['id'] as Object);
      }

      if (mounted) {
        AppToast.showSuccess(context, 'Pengeluaran berhasil diperbarui');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildMainCard(),
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
                  'Detail Pengeluaran',
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
                      onTap: _deleteExpense,
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

  Widget _buildMainCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
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
          // Icon and Date Row
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1EDD8)),
                ),
                child: Center(
                  child: Image.asset(
                    _resolveIconPath(_selectedKategoriIcon),
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.wallet,
                      color: Color(0xFFF8BD00),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Nominal
          const Text(
            'Nominal Pengeluaran (Rp)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontFamily: 'Poppins',
            ),
            decoration: _inputDecoration('0').copyWith(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFamily: 'Poppins',
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Wajib diisi';
              final parsed =
                  double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (parsed <= 0) return 'Nominal harus lebih dari 0';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Kategori
          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showKategoriPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedKategoriName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sumber Dana
          const Text(
            'Sumber Dana',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _selectedSource == 'operasional'
                  ? const Color(0xFFFFF7ED)
                  : AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedSource == 'operasional'
                    ? const Color(0xFFF8BD00)
                    : const Color(0xFFD1EDD8),
                width: 1.5,
              ),
            ),
            child: Text(
              _selectedSource == 'operasional'
                  ? 'Kas Operasional (Data Lama)'
                  : 'Kas Warung',
              style: TextStyle(
                color: _selectedSource == 'operasional'
                    ? const Color(0xFFB45309)
                    : AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Keterangan
          const Text(
            'Keterangan / Catatan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _keteranganController,
            maxLines: 3,
            style: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
            decoration: _inputDecoration(
              'Contoh: Beli bensin, Bayar listrik...',
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
          onPressed: _isLoading ? null : _saveExpense,
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
                  'SIMPAN PERUBAHAN',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1EDD8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1EDD8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary),
      ),
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
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.withValues(alpha: 0.1),
                        thickness: 1,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedKategoriId == cat['id'];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          leading: Image.asset(
                            _resolveIconPath(cat['icon'] as String?),
                            width: 32,
                            height: 32,
                          ),
                          title: Text(
                            cat['nama_kategori'] as String? ?? 'Lainnya',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedKategoriId = cat['id'] as String?;
                              _selectedKategoriName =
                                  cat['nama_kategori'] as String? ?? 'Lainnya';
                              _selectedKategoriIcon =
                                  cat['icon'] as String? ??
                                  'LainnyaPribadi.png';
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
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
