import 'package:catatcuan_mobile/core/services/settings_profile_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EditWarungPage extends StatefulWidget {
  const EditWarungPage({super.key, required this.initialData});

  final SettingsProfileData initialData;

  @override
  State<EditWarungPage> createState() => _EditWarungPageState();
}

class _EditWarungPageState extends State<EditWarungPage> {
  late final TextEditingController _warungNameController;
  late final TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _warungNameController =
        TextEditingController(text: widget.initialData.warungName);
    _addressController = TextEditingController(text: widget.initialData.address);
  }

  @override
  void dispose() {
    _warungNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveWarung() async {
    final warungName = _warungNameController.text.trim();
    final address = _addressController.text.trim();

    if (warungName.isEmpty) {
      AppToast.showInfo(context, 'Nama warung harus diisi');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SettingsProfileService.updateWarungData(
        warungId: widget.initialData.warungId,
        warungName: warungName,
        address: address,
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Gagal menyimpan data warung: $e');
      }
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
          'Edit Data Warung',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('NAMA WARUNG'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _warungNameController,
                hintText: 'Masukkan nama warung',
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              _buildLabel('ALAMAT WARUNG'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hintText: 'Masukkan alamat warung',
                keyboardType: TextInputType.streetAddress,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWarung,
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
                          'Simpan Perubahan',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hintText,
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
    );
  }
}
