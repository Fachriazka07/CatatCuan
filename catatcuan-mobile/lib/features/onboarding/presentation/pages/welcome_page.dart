import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20), // Top padding
                    // Hero Image - Takes maximum meaningful space
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: 440 / 415,
                          child: Image.asset(
                            'assets/onboarding/welcome.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ), 
                    ),
                    const SizedBox(height: 24),
                    // Texts
                    Text(
                      'Selamat Datang di CatatCuan!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kelola warung lebih modern, catat hutang jadi aman.',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20), // Bottom padding before Wave
                  ],
                ),
              ),
            ),
          ),

          // Bottom Wave Section - Fixed Height 257
          ClipPath(
            clipper: BottomWaveClipper(),
            child: Container(
              height: 257, // User requested 257px
              width: double.infinity,
              color: AppTheme.primary,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30), // Adjusted padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   // Create Account Button (Yellow)
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: const Color(0xFF111827),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Daftar'),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Login Link
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                           const TextSpan(text: 'Sudah Punya Akun? '),
                           TextSpan(
                             text: 'Masuk',
                             style: GoogleFonts.inter(
                               fontWeight: FontWeight.bold,
                               color: AppTheme.secondary,
                             ),
                           ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 60); // Start slightly down

    // The Wave
    final firstControlPoint = Offset(size.width / 4, 0);
    final firstEndPoint = Offset(size.width / 2.25, 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    final secondControlPoint = Offset(size.width - (size.width / 3.25), 90);
    final secondEndPoint = Offset(size.width, 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
