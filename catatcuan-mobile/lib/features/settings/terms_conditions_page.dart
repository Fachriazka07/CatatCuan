import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Syarat & Ketentuan',
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
            _buildSectionCard(
              title: 'Penggunaan Aplikasi',
              content:
                  'CatatCuan digunakan untuk membantu pencatatan warung seperti produk, penjualan, pengeluaran, buku kas, dan piutang. Kamu bertanggung jawab atas data yang kamu input sendiri.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Keamanan Akun',
              content:
                  'Kamu wajib menjaga nomor HP, password, dan kode OTP agar tidak dibagikan ke orang lain. Semua aktivitas yang terjadi di akun menjadi tanggung jawab pemilik akun.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Ketersediaan Layanan',
              content:
                  'Kami berusaha menjaga aplikasi tetap berjalan dengan baik, namun sewaktu-waktu layanan bisa mengalami pembaruan, perbaikan, atau gangguan teknis.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Perubahan Ketentuan',
              content:
                  'Syarat dan ketentuan ini dapat diperbarui dari waktu ke waktu untuk menyesuaikan pengembangan fitur dan kebutuhan layanan CatatCuan.',
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
        'Halaman ini menjelaskan aturan umum penggunaan CatatCuan secara singkat dan mudah dipahami.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.6,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
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
