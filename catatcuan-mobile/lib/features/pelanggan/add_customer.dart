import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) {
        throw Exception('User tidak ditemukan');
      }

      final warung = await _supabase
          .from('WARUNG')
          .select('id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (warung == null) {
        throw Exception('Data warung tidak ditemukan');
      }

      final warungId = warung['id'];

      // Insert ke tabel PELANGGAN
      await _supabase.from('PELANGGAN').insert({
        'warung_id': warungId,
        'nama': _namaController.text.trim(),
        'alamat': _alamatController.text.trim().isEmpty ? null : _alamatController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'total_hutang': 0, // Default no debt
      });

      if (mounted) {
        AppToast.showSuccess(context, 'Pelanggan berhasil ditambahkan');
        context.pop(true);
      }
    } catch (e) {
      debugPrint('Error saving customer: $e');
      if (mounted) {
        AppToast.showError(context, 'Gagal menambahkan pelanggan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white background
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(statusBarHeight),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                      ],
                    ),
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
        color: AppTheme.primary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tambahkan Pelanggan',
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
              child: const Icon(Icons.close, color: Colors.black, size: 24),
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
          _buildFieldLabel('Nama'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _namaController,
            hintText: 'INPUT NAMA PELANGGAN',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama harus diisi';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          _buildFieldLabel('Alamat (OPSIONAL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _alamatController,
            hintText: 'INPUT ALAMAT PELANGGAN',
          ),
          
          const SizedBox(height: 20),
          
          _buildFieldLabel('Nomor Telepon (OPSIONAL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hintText: 'INPUT TELEPON PELANGGAN',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600, // SemiBold
        color: Color(0xFF6B7280), // Gray 500
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151), // Gray 700
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
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
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8BD00), // The yellow color
          foregroundColor: Colors.white,
          elevation: 4, // Drop shadow to match visual
          shadowColor: const Color(0xFFF8BD00).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // Fully rounded
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'SIMPAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }
}
