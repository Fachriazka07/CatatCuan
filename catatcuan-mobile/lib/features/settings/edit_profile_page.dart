import 'package:catatcuan_mobile/core/services/settings_profile_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.initialData});

  final SettingsProfileData initialData;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ownerNameController = TextEditingController(text: widget.initialData.ownerName);
    _phoneController = TextEditingController(text: widget.initialData.phoneNumber);
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String rawPhone) {
    var phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('08')) {
      phone = '62${phone.substring(1)}';
    }
    return phone;
  }

  Future<void> _saveProfile() async {
    final ownerName = _ownerNameController.text.trim();
    final phone = _normalizePhone(_phoneController.text.trim());

    if (ownerName.isEmpty) {
      AppToast.showInfo(context, 'Nama pemilik harus diisi');
      return;
    }

    if (phone.isEmpty) {
      AppToast.showInfo(context, 'Nomor telepon harus diisi');
      return;
    }

    if (!phone.startsWith('62') || phone.length < 10 || phone.length > 14) {
      AppToast.showInfo(context, 'Nomor telepon tidak valid');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SettingsProfileService.updateOwnerProfile(
        userId: widget.initialData.userId,
        warungId: widget.initialData.warungId,
        ownerName: ownerName,
        phoneNumber: phone,
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Gagal menyimpan profil: $e');
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
          'Edit Profil',
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
              _buildLabel('NAMA PEMILIK'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ownerNameController,
                hintText: 'Masukkan nama pemilik',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              _buildLabel('NOMOR TELEPON'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hintText: 'Contoh: 62812xxxxxxx',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
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
