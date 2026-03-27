import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Kebijakan Privasi',
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 16),
            _buildPolicyCard(
              title: 'Data Yang Disimpan',
              content:
                  'CatatCuan menyimpan data akun, data warung, produk, penjualan, pengeluaran, buku kas, dan hutang yang kamu catat di aplikasi.',
            ),
            const SizedBox(height: 12),
            _buildPolicyCard(
              title: 'Tujuan Penggunaan Data',
              content:
                  'Data digunakan untuk membantu pencatatan warung, menampilkan laporan, dan menjaga agar data warung tetap bisa diakses saat kamu login kembali.',
            ),
            const SizedBox(height: 12),
            _buildPolicyCard(
              title: 'Keamanan Data',
              content:
                  'CatatCuan berusaha menjaga data agar tidak mudah diakses oleh pihak lain tanpa izin. Password dan data penting diproses untuk kebutuhan aplikasi.',
            ),
            const SizedBox(height: 12),
            _buildPolicyCard(
              title: 'Kontrol Pengguna',
              content:
                  'Kamu tetap bisa memperbarui data profil, data warung, dan pengaturan lain dari halaman pengaturan aplikasi.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Text(
        'CatatCuan menghargai privasi pengguna. Penjelasan di halaman ini dibuat singkat dan sederhana agar mudah dipahami.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.6,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
