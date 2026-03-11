import 'package:catatcuan_mobile/core/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingIntro extends StatelessWidget {

  const OnboardingIntro({
    super.key,
    required this.onNext,
  });
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Stack(
        children: [
          // 1. White Shape Overlay (slanted area for image)
          ClipPath(
            clipper: _SlantedWhiteClipper(),
            child: Container(
              width: double.infinity,
              height: 520,
              color: Colors.white,
            ),
          ),

          // 2. Illustration Image
          Positioned(
            top: 80,
            left: 26,
            right: 26,
            child: Image.asset(
              'assets/onboarding/intro.png',
              height: 350,
              fit: BoxFit.contain,
            ),
          ),

          // 3. Text Content
          Positioned(
            top: 550,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, Juragan!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kelola warung jadi lebih rapi dan untung.',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 4. CTA Button
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8BD00),
                  foregroundColor: const Color(0xFF0B3D21),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                ),
                child: Text(
                  'Mulai Sekarang',
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
    );
  }
}

class _SlantedWhiteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 30.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 100);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
