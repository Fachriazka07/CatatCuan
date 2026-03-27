import 'package:catatcuan_mobile/core/services/settings_preferences_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DefaultPeriodPage extends StatefulWidget {
  const DefaultPeriodPage({super.key});

  @override
  State<DefaultPeriodPage> createState() => _DefaultPeriodPageState();
}

class _DefaultPeriodPageState extends State<DefaultPeriodPage> {
  AppDefaultPeriod _selectedPeriod = AppDefaultPeriod.bulanan;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultPeriod();
  }

  Future<void> _loadDefaultPeriod() async {
    final period = await SettingsPreferencesService.getDefaultPeriod();
    if (!mounted) return;

    setState(() {
      _selectedPeriod = period;
      _isLoading = false;
    });
  }

  Future<void> _saveDefaultPeriod() async {
    setState(() => _isSaving = true);
    await SettingsPreferencesService.setDefaultPeriod(_selectedPeriod);

    if (!mounted) return;

    setState(() => _isSaving = false);
    AppToast.showSuccess(context, 'Periode default berhasil disimpan');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Periode Default',
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih periode yang akan ditampilkan pertama kali saat membuka laporan dan stats.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...AppDefaultPeriod.values.map(_buildPeriodOption),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDefaultPeriod,
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
                                'Simpan',
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

  Widget _buildPeriodOption(AppDefaultPeriod period) {
    final isSelected = _selectedPeriod == period;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFD1EDD8),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  SettingsPreferencesService.getLabel(period),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.primary : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
