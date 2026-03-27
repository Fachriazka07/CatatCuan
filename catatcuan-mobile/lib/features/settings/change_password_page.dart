import 'package:catatcuan_mobile/core/services/settings_security_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      AppToast.showInfo(context, 'Password lama harus diisi');
      return;
    }

    if (newPassword.isEmpty) {
      AppToast.showInfo(context, 'Password baru harus diisi');
      return;
    }

    if (newPassword.length < 6) {
      AppToast.showInfo(context, 'Password baru minimal 6 karakter');
      return;
    }

    if (newPassword != confirmPassword) {
      AppToast.showInfo(context, 'Konfirmasi password baru tidak cocok');
      return;
    }

    if (currentPassword == newPassword) {
      AppToast.showInfo(context, 'Password baru harus berbeda dari password lama');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SettingsSecurityService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        AppToast.showSuccess(context, 'Password berhasil diperbarui');
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();
      if (message.contains('change_mobile_user_password') ||
          message.contains('PGRST202')) {
        AppToast.showError(
          context,
          'Fitur ubah password belum aktif di database. Jalankan migration SQL terlebih dulu.',
        );
      } else if (message.contains('CURRENT_PASSWORD_INVALID')) {
        AppToast.showError(context, 'Password lama tidak sesuai');
      } else if (message.contains('PASSWORD_TOO_SHORT')) {
        AppToast.showInfo(context, 'Password baru minimal 6 karakter');
      } else {
        AppToast.showError(context, 'Gagal mengubah password: $e');
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
          'Ubah Password',
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
              _buildLabel('PASSWORD LAMA'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _currentPasswordController,
                hintText: 'Masukkan password lama',
                obscureText: _obscureCurrent,
                onToggleVisibility: () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              _buildLabel('PASSWORD BARU'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newPasswordController,
                hintText: 'Masukkan password baru',
                obscureText: _obscureNew,
                onToggleVisibility: () {
                  setState(() => _obscureNew = !_obscureNew);
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              _buildLabel('KONFIRMASI PASSWORD BARU'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: 'Ulangi password baru',
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              Text(
                'Gunakan minimal 6 karakter agar password lebih aman.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePassword,
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
                          'Simpan Password',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF6B7280),
          ),
        ),
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
