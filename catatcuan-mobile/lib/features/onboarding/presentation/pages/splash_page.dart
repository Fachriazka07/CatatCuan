import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Step 1: Start
    if (mounted) setState(() => _progress = 0.1);
    await Future.delayed(const Duration(milliseconds: 500)); // Min wait

    // Step 2: Check Session (Local)
    if (mounted) setState(() => _progress = 0.4);
    
    final userId = await SessionService.getUserId();
    
    if (userId == null) {
      if (mounted) setState(() => _progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go('/welcome');
      return;
    }

    // Step 3: Check Warung
    if (mounted) setState(() => _progress = 0.7);
    try {
      final warung = await Supabase.instance.client
          .from('WARUNG')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) setState(() => _progress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        if (warung != null) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
         setState(() => _progress = 1.0);
         context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3A9B6B),
              Color(0xFF13B158),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Title with Poppins
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Catat',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Cuan',
                          style: TextStyle(color: AppTheme.secondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress Bar
            Positioned(
              bottom: 80,
              left: 60,
              right: 60,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                      value: _progress,
                      minHeight: 8, // Increased height
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat data...',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
