import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdjustmentPage extends StatefulWidget {
  const AdjustmentPage({super.key});

  @override
  State<AdjustmentPage> createState() => _AdjustmentPageState();
}

class _AdjustmentPageState extends State<AdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;

  final TextEditingController _tanggalController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();

  bool _isLoading = false;
  String _targetKas = 'laci'; // 'laci' or 'kas'

  void _closePage() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(Duration.zero, () {
      if (mounted && Navigator.of(context).canPop()) {
        context.pop();
      }
    });
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final warungId = _cache.warungId;
        final double saldoBaru = double.parse(
          _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );

        // 1. Calculate delta based on CURRENT balance
        final double currentTargetBal = _targetKas == 'laci'
            ? _cache.saldoAwal
            : _cache.uangKas;
        final double delta = saldoBaru - currentTargetBal;

        // Total total warung also shifts by this delta
        final double currentTotal = _cache.saldoAwal + _cache.uangKas;
        final double saldoSetelah = currentTotal + delta;

        // 2. Insert BUKU_KAS
        await _supabase.from('BUKU_KAS').insert({
          'warung_id': warungId,
          'tanggal': _selectedDate.toIso8601String(),
          'tipe': 'adjustment', // Using the new enum value
          'sumber': 'adjustment', // Using the new enum value
          'amount': delta.abs(),
          'saldo_setelah': saldoSetelah,
          'keterangan':
              '[KOREKSI ${_targetKas.toUpperCase()}] Asal: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(currentTargetBal)} ➔ Jadi: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(saldoBaru)}. ${_catatanController.text.trim()}',
        });

        // 3. Update WARUNG balance
        final Map<String, dynamic> updateData = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_targetKas == 'laci') {
          _cache.saldoAwal = saldoBaru;
          updateData['saldo_awal'] = _cache.saldoAwal;
        } else {
          _cache.uangKas = saldoBaru;
          updateData['uang_kas'] = _cache.uangKas;
        }

        await _supabase.from('WARUNG').update(updateData).eq('id', warungId!);

        if (mounted) {
          AppToast.showSuccess(context, 'Saldo Berhasil Disesuaikan');
          context.pop(true);
        }
      } catch (e) {
        debugPrint('Error saving adjustment: $e');
        if (mounted) {
          AppToast.showError(context, 'Gagal mencatat penyesuaian: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(statusBarHeight),
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

  Widget _buildHeader(double statusBarHeight) {
    return Container(
      height: statusBarHeight + 88,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 12, 16, 16),
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
          const Text(
            'Penyesuaian Saldo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
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
    );
  }

  Widget _buildTopCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          _buildFieldLabel('Tanggal'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Alasan / Catatan (Opsional)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _catatanController,
            hintText: 'MISAL: SELISIH HITUNG...',
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          _buildFieldLabel('Pilih Tempat Uang'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSourceChip('laci', 'UANG LACI', _cache.saldoAwal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSourceChip('kas', 'UANG KAS', _cache.uangKas),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildFieldLabel('Saldo Sebenarnya (Rp)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _jumlahController,
            hintText: 'INPUT SALDO AKHIR...',
            keyboardType: TextInputType.number,
            isAmount: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Wajib diisi';
              return null;
            },
          ),
          const SizedBox(height: 8),
          const Text(
            '*Sistem akan menyesuaikan saldo otomatis berdasarkan nilai yang Anda input.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String value, String label, double bal) {
    final bool isSel = _targetKas == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _targetKas = value;
          // Set initial value to current balance for easier editing
          if (_jumlahController.text.isEmpty || _jumlahController.text == '0') {
            _jumlahController.text = NumberFormat.currency(
              locale: 'id_ID',
              symbol: '',
              decimalDigits: 0,
            ).format(bal).trim();
          }
        });
      },
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
                  'SIMPAN PENYESUAIAN',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isAmount = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: isAmount ? [CurrencyInputFormatter()] : null,
      validator: validator,
      style: TextStyle(
        fontSize: isAmount ? 20 : 16,
        fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
        color: const Color(0xFF374151),
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: isAmount ? 'Rp ' : null,
        prefixStyle: isAmount
            ? const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )
            : null,
        hintStyle: TextStyle(
          color: const Color(0xFF6B7280).withValues(alpha: 0.5),
          fontSize: isAmount ? 20 : 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
