import 'package:catatcuan_mobile/features/home/presentation/pages/home_page.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:catatcuan_mobile/features/produk/insert_product.dart';
import 'package:catatcuan_mobile/features/produk/product-list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/pages/splash_page.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:catatcuan_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:catatcuan_mobile/features/auth/presentation/pages/register_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      // Feature Placeholders
      GoRoute(
        path: '/produk',
        builder: (context, state) => const ProductListPage(),
      ),
      GoRoute(
        path: '/produk/add',
        builder: (context, state) => const InsertProductPage(),
      ),
      GoRoute(
        path: '/pengeluaran',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Pengeluaran'))),
      ),
      GoRoute(
        path: '/buku-kas',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Buku Kas'))),
      ),
      GoRoute(
        path: '/hutang',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Hutang'))),
      ),
      GoRoute(
        path: '/pelanggan',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Pelanggan'))),
      ),
      GoRoute(
        path: '/laporan',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Laporan'))),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Stats'))),
      ),
      GoRoute(
        path: '/setting',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Halaman Setting'))),
      ),
    ],
  );
}
