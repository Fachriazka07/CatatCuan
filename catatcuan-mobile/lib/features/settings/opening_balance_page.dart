import 'package:catatcuan_mobile/core/services/settings_master_data_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:catatcuan_mobile/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OpeningBalancePage extends StatefulWidget {
  const OpeningBalancePage({super.key});

  @override
  State<OpeningBalancePage> createState() => _OpeningBalancePageState();
}

class _OpeningBalancePageState extends State<OpeningBalancePage> {
  final _drawerController = TextEditingController();
  final _cashController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    setState(() => _isLoading = true);
    try {
      final balances = await SettingsMasterDataService.getOpeningBalances();
      if (!mounted) return;

      _drawerController.text = formatIdrNumber(balances['saldo_awal'] ?? 0);
      _cashController.text = formatIdrNumber(balances['uang_kas'] ?? 0);

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(context, 'Gagal memuat saldo awal: $e');
    }
  }

  double _parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _saveBalances() async {
    final drawerBalance = _parseAmount(_drawerController.text);
    final cashBalance = _parseAmount(_cashController.text);

    setState(() => _isSaving = true);
    try {
      await SettingsMasterDataService.updateOpeningBalances(
        drawerBalance: drawerBalance,
        cashBalance: cashBalance,
      );

      if (!mounted) return;
      AppToast.showSuccess(context, 'Saldo awal berhasil diperbarui');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal menyimpan saldo awal: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Saldo Awal',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atur modal awal warung untuk uang laci dan uang kas. Perubahan di halaman ini tidak menambah riwayat transaksi baru.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildLabel('SALDO AWAL UANG LACI'),
                    const SizedBox(height: 8),
                    _buildCurrencyField(
                      controller: _drawerController,
                      hintText: '0',
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('SALDO AWAL UANG KAS'),
                    const SizedBox(height: 8),
                    _buildCurrencyField(
                      controller: _cashController,
                      hintText: '0',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBalances,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan Saldo Awal',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final drawerAmount = _parseAmount(_drawerController.text);
    final cashAmount = _parseAmount(_cashController.text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Saat Ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow('Uang Laci', _formatCurrency(drawerAmount)),
          const SizedBox(height: 10),
          _buildSummaryRow('Uang Kas', _formatCurrency(cashAmount)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: 'Rp ',
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1EDD8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1EDD8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
