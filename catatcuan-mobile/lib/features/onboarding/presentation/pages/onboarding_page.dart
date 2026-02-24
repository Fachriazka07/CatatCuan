import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/widgets/onboarding_business_type.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/widgets/onboarding_capital.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/widgets/onboarding_intro.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/widgets/onboarding_profile.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/widgets/onboarding_step_intro.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Page indices:
/// 0 = Welcome Intro
/// 1 = Step Intro: Business Type (1/3)
/// 2 = Business Type Form
/// 3 = Step Intro: Profile (2/3)
/// 4 = Profile Form
/// 5 = Step Intro: Capital (3/3)
/// 6 = Capital Form

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Total pages in PageView
  static const int _totalPages = 7;

  // Pages that are form pages (show bottom bar)
  static const List<int> _formPages = [];

  // Form Data
  String? _selectedBusinessType;
  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _cashInDrawerController = TextEditingController();
  final _personalCapitalController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _cashInDrawerController.dispose();
    _personalCapitalController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitData();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitData() async {
    setState(() => _isLoading = true);
    
    final userId = await SessionService.getUserId();
    
    if (userId == null) {
      context.go('/login');
      return;
    }

    try {
      final cashInDrawer = double.tryParse(_cashInDrawerController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final personalCapital = double.tryParse(_personalCapitalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      
      // 0. Get phone from USERS table
      final userRow = await Supabase.instance.client
          .from('USERS')
          .select('phone_number')
          .eq('id', userId)
          .single();
      final phone = userRow['phone_number'] as String;

      // 1. Create Warung (phone auto-filled from registration)
      final warungResponse = await Supabase.instance.client
          .from('WARUNG')
          .insert({
            'user_id': userId,
            'nama_pemilik': _ownerNameController.text.trim(),
            'nama_warung': _businessNameController.text.trim(),
            'alamat': _businessAddressController.text.trim(),
            'phone': phone,
            'saldo_awal': cashInDrawer,
            'uang_kas': personalCapital,
          })
          .select()
          .single();
      
      final warungId = warungResponse['id'];

      // 2. Record Initial Balance (Uang Laci)
      if (cashInDrawer > 0) {
        await Supabase.instance.client.from('BUKU_KAS').insert({
          'warung_id': warungId,
          'tipe': 'masuk',
          'sumber': 'saldo_awal',
          'amount': cashInDrawer,
          'saldo_setelah': cashInDrawer,
          'keterangan': 'Saldo Awal (Uang Laci)',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Record Capital (Uang Pribadi)
      if (personalCapital > 0) {
         final currentBalance = cashInDrawer + personalCapital;
         await Supabase.instance.client.from('BUKU_KAS').insert({
          'warung_id': warungId,
          'tipe': 'masuk',
          'sumber': 'saldo_awal',
          'amount': personalCapital,
          'saldo_setelah': currentBalance,
          'keterangan': 'Modal Tambahan (Uang Pribadi)',
          'created_at': DateTime.now().add(const Duration(seconds: 1)).toIso8601String(),
        });
      }

      // 4. Seed Categories & Satuan
      await _seedCategories(warungId);
      await _seedSatuan(warungId);

      if (mounted) {
        context.go('/home');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seedCategories(String warungId) async {
    try {
      // Fetch active master categories from admin-managed table
      final masterData = await Supabase.instance.client
          .from('MASTER_KATEGORI_PRODUK')
          .select('id, nama_kategori, icon, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (masterData.isEmpty) {
        // Fallback: if no master data, use defaults (no master_kategori_id)
        final fallback = [
          {'nama': 'Sembako', 'icon': 'Sembako.png'},
          {'nama': 'Cemilan', 'icon': 'Cemilan.png'},
          {'nama': 'Minuman', 'icon': 'Minuman.png'},
          {'nama': 'Bumbu Dapur', 'icon': 'BumbuDapur.png'},
          {'nama': 'Rokok', 'icon': 'Rokok.png'},
          {'nama': 'Obat-obatan', 'icon': 'Obat.png'},
          {'nama': 'Perlengkapan Mandi', 'icon': 'PerlengkapanMandi.png'},
          {'nama': 'Lainnya', 'icon': 'Lainya.png'},
        ];
        final cleanData = fallback.asMap().entries.map((e) => {
              'warung_id': warungId,
              'nama_kategori': e.value['nama'],
              'icon': e.value['icon'],
              'sort_order': e.key,
            }).toList();
        await Supabase.instance.client.from('KATEGORI_PRODUK').insert(cleanData);
        return;
      }

      // Copy master categories to user's warung (with master ID reference)
      final cleanData = masterData.map((cat) => {
            'warung_id': warungId,
            'nama_kategori': cat['nama_kategori'],
            'icon': cat['icon'],
            'sort_order': cat['sort_order'] ?? 0,
            'master_kategori_id': cat['id'],
          }).toList();

      await Supabase.instance.client.from('KATEGORI_PRODUK').insert(cleanData);
    } catch (e) {
      debugPrint('Error seeding categories: $e');
    }
  }

  Future<void> _seedSatuan(String warungId) async {
    try {
      final masterData = await Supabase.instance.client
          .from('MASTER_SATUAN')
          .select('id, nama_satuan, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (masterData.isEmpty) {
        // Fallback defaults
        final fallback = ['PCS', 'KG', 'GRAM', 'LITER', 'ML', 'PAK', 'DUS',
            'LUSIN', 'BOTOL', 'BUNGKUS', 'SACHET', 'KALENG', 'RENTENG', 'KARUNG'];
        final cleanData = fallback.asMap().entries.map((e) => {
              'warung_id': warungId,
              'nama_satuan': e.value,
              'sort_order': e.key,
            }).toList();
        await Supabase.instance.client.from('SATUAN_PRODUK').insert(cleanData);
        return;
      }

      final cleanData = masterData.map((sat) => {
            'warung_id': warungId,
            'nama_satuan': sat['nama_satuan'],
            'sort_order': sat['sort_order'] ?? 0,
            'master_satuan_id': sat['id'],
          }).toList();

      await Supabase.instance.client.from('SATUAN_PRODUK').insert(cleanData);
    } catch (e) {
      debugPrint('Error seeding satuan: $e');
    }
  }

  /// Check if current page is a form page (shows bottom bar)
  bool get _isFormPage => _formPages.contains(_currentPage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                // Page 0: Welcome Intro
                OnboardingIntro(onNext: _nextPage),

                // Page 1: Step Intro - Business Type (1/3)
                OnboardingStepIntro(
                  imagePath: 'assets/onboarding/step.png',
                  title: 'Apa Usaha Anda?',
                  subtitle: 'Beritahu kami jenis jualan Anda, biar daftar barangnya lebih pas.',
                  buttonText: 'Pilih Jenis Usaha',
                  currentStep: 1,
                  totalSteps: 3,
                  onPressed: _nextPage,
                ),

                // Page 2: Business Type Form
                OnboardingBusinessType(
                  selectedType: _selectedBusinessType,
                  onTypeSelected: (value) => setState(() => _selectedBusinessType = value),
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),

                // Page 3: Step Intro - Profile (2/3)
                OnboardingStepIntro(
                  imagePath: 'assets/onboarding/step.png',
                  title: 'Lengkapi Profil Usaha',
                  subtitle: 'Isi nama dan alamat usahamu supaya laporan lebih rapi.',
                  buttonText: 'Isi Profil',
                  currentStep: 2,
                  totalSteps: 3,
                  onPressed: _nextPage,
                ),

                // Page 4: Profile Form
                // Page 4: Profile Form
                OnboardingProfile(
                  ownerNameController: _ownerNameController,
                  nameController: _businessNameController,
                  addressController: _businessAddressController,
                  onNext: () {
                    if (_ownerNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama lengkap wajib diisi')),
                      );
                      return;
                    }
                    if (_businessNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama usaha wajib diisi')),
                      );
                      return;
                    }
                    _nextPage();
                  },
                  onBack: _previousPage,
                ),

                // Page 5: Step Intro - Capital (3/3)
                OnboardingStepIntro(
                  imagePath: 'assets/onboarding/step.png',
                  title: 'Modal Awal',
                  subtitle: 'Masukkan saldo kas yang ada saat ini biar catatan keuanganmu langsung akurat.',
                  buttonText: 'Isi Modal',
                  currentStep: 3,
                  totalSteps: 3,
                  onPressed: _nextPage,
                ),

                // Page 6: Capital Form
                OnboardingCapital(
                  cashController: _cashInDrawerController,
                  capitalController: _personalCapitalController,
                  onNext: _nextPage,
                  onBack: _previousPage,
                ),
              ],
            ),
          ),
          if (_isFormPage) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : _previousPage,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      // Validation based on current form page
                      if (_currentPage == 2 && _selectedBusinessType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pilih jenis usaha dulu')),
                        );
                        return;
                      }
                      if (_currentPage == 4) {
                        if (_ownerNameController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama lengkap wajib diisi')),
                          );
                          return;
                        }
                        if (_businessNameController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama usaha wajib diisi')),
                          );
                          return;
                        }
                      }
                      _nextPage();
                    },
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                  : Text(_currentPage == 6 ? 'Selesai' : 'Lanjut'),
            ),
          ),
        ],
      ),
    );
  }
}
