import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
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
  String _sourceKas = 'laci'; // 'laci' or 'kas'
  String _targetKas = 'kas'; // 'laci' or 'kas'

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
    if (_sourceKas == _targetKas) {
      AppToast.showWarning(context, 'Sumber dan tujuan tidak boleh sama');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final warungId = _cache.warungId;
        final double amount = double.parse(
          _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );

        // 1. Calculate saldo_setelah (Total warung doesn't change on transfer, but for bookkeeping we record it)
        final double currentTotal = _cache.saldoAwal + _cache.uangKas;

        // 2. Insert BUKU_KAS
        await _supabase.from('BUKU_KAS').insert({
          'warung_id': warungId,
          'tanggal': _selectedDate.toIso8601String(),
          'tipe': 'transfer',
          'sumber': 'transfer',
          'amount': amount,
          'saldo_setelah': currentTotal,
          'keterangan':
              '[TRANSFER: ${_sourceKas.toUpperCase()} ➔ ${_targetKas.toUpperCase()}] ${_catatanController.text.trim()}',
        });

        // 3. Update WARUNG balance
        final Map<String, dynamic> updateData = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_sourceKas == 'laci') {
          _cache.saldoAwal -= amount;
          _cache.uangKas += amount;
        } else {
          _cache.uangKas -= amount;
          _cache.saldoAwal += amount;
        }

        updateData['saldo_awal'] = _cache.saldoAwal;
        updateData['uang_kas'] = _cache.uangKas;

        await _supabase.from('WARUNG').update(updateData).eq('id', warungId!);

        if (mounted) {
          AppToast.showSuccess(context, 'Transfer Berhasil Dicatat');
          context.pop(true);
        }
      } catch (e) {
        debugPrint('Error saving transfer: $e');
        if (mounted) {
          AppToast.showError(context, 'Gagal mencatat transfer: $e');
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
                      _buildTransferFlowCard(),
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
            'Transfer / Pemindahan',
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
          _buildFieldLabel('Catatan'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _catatanController,
            hintText: 'TAMBAH CATATAN...',
          ),
        ],
      ),
    );
  }

  Widget _buildTransferFlowCard() {
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Dari'),
                    const SizedBox(height: 8),
                    _buildSourceChip('dari', _sourceKas, (v) {
                      setState(() {
                        _sourceKas = v;
                        _targetKas = v == 'laci' ? 'kas' : 'laci';
                      });
                    }),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, right: 8, top: 24),
                child: Icon(Icons.arrow_forward, color: AppTheme.primary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Ke'),
                    const SizedBox(height: 8),
                    _buildSourceChip('ke', _targetKas, (v) {
                      setState(() {
                        _targetKas = v;
                        _sourceKas = v == 'laci' ? 'kas' : 'laci';
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('Jumlah Transfer (Rp)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _jumlahController,
            hintText: '0',
            keyboardType: TextInputType.number,
            isAmount: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Wajib diisi';
              final val =
                  double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (val <= 0) return 'Harus > 0';

              final double balance = _sourceKas == 'laci'
                  ? _cache.saldoAwal
                  : _cache.uangKas;
              if (val > balance) return 'Saldo tidak cukup';

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(
    String type,
    String currentVal,
    ValueChanged<String> onSelected,
  ) {
    return Column(
      children: [
        _buildChipItem('laci', 'UANG LACI', currentVal == 'laci', onSelected),
        const SizedBox(height: 8),
        _buildChipItem('kas', 'UANG KAS', currentVal == 'kas', onSelected),
      ],
    );
  }

  Widget _buildChipItem(
    String value,
    String label,
    bool isSelected,
    ValueChanged<String> onSelected,
  ) {
    final double bal = value == 'laci' ? _cache.saldoAwal : _cache.uangKas;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFD1EDD8),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primary : Colors.grey,
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
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : Colors.grey,
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
                  'TRANSFER SEKARANG',
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
