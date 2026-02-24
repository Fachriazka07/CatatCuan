import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catatcuan_mobile/core/widgets/gradient_background.dart';

/// Reusable step intro screen shown before each onboarding form.
/// Displays an illustration, title, subtitle, step dots, and a CTA button.
class OnboardingStepIntro extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String buttonText;
  final int currentStep; // 1-based (1, 2, 3)
  final int totalSteps;
  final VoidCallback onPressed;

  const OnboardingStepIntro({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.currentStep,
    required this.totalSteps,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GradientBackground(
      child: Stack(
        children: [
          // 1. White Shape Overlay (slanted)
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
            top: screenHeight * (60 / 956),
            left: 26,
            right: 26,
            child: Image.asset(
              imagePath,
              height: screenHeight * (350 / 956),
              fit: BoxFit.contain,
            ),
          ),

          // 3. Text Content + Step Dots
          Positioned(
            top: screenHeight * 0.62,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromRGBO(242, 246, 255, 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Step Dots (centered)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalSteps, (index) {
                      final isActive = index == (currentStep - 1);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFF8BD00)
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // 4. CTA Button (300x60, centered)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.25),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8BD00),
                    foregroundColor: const Color(0xFF0B3D21),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    elevation: 0,
                    minimumSize: const Size(300, 60),
                  ),
                  child: Text(
                    buttonText,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
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
    const r = 16.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 176);
    path.lineTo(r, size.height - (r * 176 / size.width));
    path.quadraticBezierTo(
      0, size.height,
      0, size.height - r,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
