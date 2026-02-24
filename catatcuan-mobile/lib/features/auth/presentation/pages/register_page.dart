import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    String phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Validasi Input Kosong
    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomer HP dan Password harus diisi')),
      );
      return;
    }

    // 2. Validasi Format Nomer HP Indonesia (08xx atau 628xx)
    // Hapus karakter non-digit jika ada
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (!phone.startsWith('08') && !phone.startsWith('628')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomer HP harus diawali 08 atau 628')),
      );
      return;
    }

    // Cek panjang digit (biasanya 10-13 digit untuk indo)
    if (phone.length < 10 || phone.length > 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomer HP tidak valid (10-13 digit)')),
      );
      return;
    }

    // 3. Normalisasi ke format E.164 (628xxx)
    if (phone.startsWith('08')) {
      phone = '62${phone.substring(1)}';
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // CUSTOM AUTH: Insert directly to USERS table
      final response = await Supabase.instance.client
          .from('USERS')
          .insert({
            'phone_number': phone,
            'password': password,
            'status': 'active',
          })
          .select()
          .single();

      if (mounted) {
        final userId = response['id'];
        
        // Save Session Locally
        await SessionService.saveSession(userId, phone);

        // Navigate to Onboarding
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        String message = 'Terjadi kesalahan, silakan coba lagi';
        if (e.toString().contains('duplicate key')) {
          message = 'Nomor HP sudah terdaftar';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'), // Show actual error
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF13B158),
                  Color(0xFF3A9B6B),
                ],
              ),
            ),
          ),
          
          // Background Blobs (Simplified representation)
          Positioned(
            top: -42,
            left: -84,
            child: Container(
              width: 286,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            top: 73,
            right: -100,
            child: Container(
              width: 265,
              height: 278,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(130),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 60,
            left: 24,
            child: InkWell(
              onTap: () => context.go('/welcome'),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8BD00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0B3D21),
                ),
              ),
            ),
          ),

          // Header Title
          Positioned(
            top: 134,
            left: 30,
            child: Text(
              'Buat Akun Baru',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Main Content Card
          Positioned.fill(
            top: 214,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Juragan!',
                      style: GoogleFonts.poppins(
                        color: AppTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mari daftarkan warung Anda.',
                      style: GoogleFonts.poppins(
                        color: const Color(0xCC6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Phone Number Field
                    Text(
                      'Nomer HP',
                      style: GoogleFonts.poppins(
                        color: const Color(0xCC6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE6FFE7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE6FFE7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    Text(
                      'Password',
                      style: GoogleFonts.poppins(
                        color: const Color(0xCC6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE6FFE7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE6FFE7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Terms and Conditions
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: const Color(0xCC2C2C2C),
                            fontSize: 12,
                          ),
                          children: [
                            const TextSpan(text: 'Dengan mendaftar, Anda menyetujui '),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: GoogleFonts.poppins(color: AppTheme.primary),
                            ),
                            const TextSpan(text: ' dan Kebijakan '),
                            TextSpan(
                              text: 'Privasi kami',
                              style: GoogleFonts.poppins(color: AppTheme.primary),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8BD00),
                          foregroundColor: const Color(0xFF0B3D21),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF0B3D21))
                            : Text(
                                'Daftar Sekarang',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                            children: [
                              const TextSpan(text: 'Sudah Punya Akun? '),
                              TextSpan(
                                text: 'Masuk di sini',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
