import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingBusinessType extends StatelessWidget {

  const OnboardingBusinessType({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onNext,
    required this.onBack,
  });
  final String? selectedType;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;

  static final List<Map<String, dynamic>> _businessTypes = [
    {
      'id': 'warung',
      'label': 'Warung Kelontong & Sembako',
      'iconPath': 'assets/icon/shop.png',
    },
    {
      'id': 'makanan',
      'label': 'Makanan & Minuman',
      'iconPath': 'assets/icon/coffee.png',
    },
    {
      'id': 'fashion',
      'label': 'Fashion & Aksesoris',
      'iconPath': 'assets/icon/laundry.png',
    },
    {
      'id': 'laundry',
      'label': 'Laundry',
      'iconPath': 'assets/icon/hanger.png',
    },
    {
      'id': 'lainya',
      'label': 'Lainya',
      'iconPath': 'assets/icon/package.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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

        Positioned(
          top: -42,
          left: -84,
          child: Container(
            width: 286,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
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
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(130),
            ),
          ),
        ),

        Positioned.fill(
          top: 140,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Jenis Usaha Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      
                        const SizedBox(height: 24),
                        ..._businessTypes.map((type) => _buildTypeCard(type)),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Navigation Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      // Tombol Back Outlined
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: onBack,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Lanjut (Primary Green)
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (selectedType != null)
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: selectedType != null ? onNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Lanjut',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> type) {
    final isSelected = selectedType == type['id'] as String;
    return GestureDetector(
      onTap: () => onTypeSelected(type['id'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFF3F4F6),
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6FFE7)),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                type['iconPath'] as String,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
