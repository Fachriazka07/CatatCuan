import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _customerServicePhone = '6287825782889';
  final _cache = DataCacheService.instance;
  String? _phone;
  bool _isLoading = true;

  String? _cleanText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? get _displayUserName => _cleanText(_cache.userName);
  String? get _displayWarungName => _cleanText(_cache.warungName);
  String? get _displayPhone => _cleanText(_phone);
  bool get _shouldShowProfileSummary =>
      _isLoading ||
      _displayUserName != null ||
      _displayWarungName != null ||
      _displayPhone != null;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final phone = await SessionService.getUserPhone();
    if (mounted) {
      setState(() {
        _phone = phone;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await SessionService.logout();
      _cache.clear();
      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error logout: $e');
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Keluar Aplikasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceholder(String title) {
    AppToast.showInfo(context, 'Fitur $title akan segera hadir');
  }

  Future<void> _openCustomerServiceWhatsApp() async {
    const message =
        'Halo CatatCuan, saya butuh bantuan penggunaan aplikasi.';
    final uri = Uri.parse(
      'https://wa.me/$_customerServicePhone?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      AppToast.showError(
        context,
        'WhatsApp tidak bisa dibuka di perangkat ini',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (_shouldShowProfileSummary) ...[
                      _buildProfileSummary(),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle('AKUN'),
                    _buildSectionCard([
                      _buildSettingsItem(
                        icon: Icons.person_outline,
                        title: 'Profil Saya',
                        subtitle: 'Lihat info profil pemilik',
                        onTap: () => context.push('/setting/profile'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.storefront_outlined,
                        title: 'Data Warung',
                        subtitle: 'Kelola nama dan alamat warung',
                        onTap: () => context.push('/setting/warung'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.lock_outline,
                        title: 'Ubah Password',
                        subtitle: 'Ganti kata sandi akun',
                        onTap: () => context.push('/setting/password'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('PREFERENSI'),
                    _buildSectionCard([
                      _buildSettingsItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Periode Default',
                        subtitle: 'Atur rentang waktu awal laporan',
                        onTap: () => context.push('/setting/default-period'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.notifications_none,
                        title: 'Notifikasi',
                        subtitle: 'Atur pengingat dan alert aplikasi',
                        onTap: () => context.push('/setting/notifications'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('DATA & WARUNG'),
                    _buildSectionCard([
                      _buildSettingsItem(
                        icon: Icons.category_outlined,
                        title: 'Kategori Produk',
                        subtitle: 'Kelola pengelompokan produk',
                        onTap: () => context.push('/setting/product-categories'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Kategori Pengeluaran',
                        subtitle: 'Atur jenis-jenis pengeluaran',
                        onTap: () => context.push('/setting/expense-categories'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.straighten_outlined,
                        title: 'Satuan Produk',
                        subtitle: 'Kelola satuan (Pcs, Kg, dll)',
                        onTap: () => context.push('/setting/product-units'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Saldo Awal',
                        subtitle: 'Atur modal awal uang laci & kas',
                        onTap: () => context.push('/setting/opening-balance'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('BANTUAN & INFO'),
                    _buildSectionCard([
                      _buildSettingsItem(
                        icon: Icons.help_outline,
                        title: 'Pusat Bantuan',
                        subtitle: 'Butuh bantuan penggunaan?',
                        onTap: _openCustomerServiceWhatsApp,
                      ),
                      _buildSettingsItem(
                        icon: Icons.info_outline,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Versi dan informasi CatatCuan',
                        onTap: () => context.push('/setting/about'),
                      ),
                      _buildSettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Kebijakan Privasi',
                        subtitle: 'Data dan keamanan pribadimu',
                        onTap: () => context.push('/setting/privacy'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('DANGER ZONE'),
                    _buildSectionCard([
                      _buildSettingsItem(
                        icon: Icons.logout,
                        title: 'Keluar Aplikasi',
                        subtitle: 'Keluar dari akun saat ini',
                        iconColor: Colors.red,
                        titleColor: Colors.red,
                        showChevron: false,
                        onTap: _showLogoutConfirmation,
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pengaturan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummary() {
    if (_isLoading) {
      return Container(
        height: 96,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1EDD8)),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    final userName = _displayUserName ?? 'Pemilik Warung';
    final warungName = _displayWarungName ?? 'Warung Kamu';
    final phone = _displayPhone;
    final avatarLabel = userName.isNotEmpty ? userName[0].toUpperCase() : 'W';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD8)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      warungName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    if (phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6B7280),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? const Color(0xFF374151),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
        ),
      ),
      trailing: showChevron
          ? const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 20,
            )
          : null,
    );
  }
}
