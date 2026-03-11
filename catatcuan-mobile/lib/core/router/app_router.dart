import 'package:catatcuan_mobile/features/home/presentation/pages/home_page.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:catatcuan_mobile/features/produk/insert_product.dart';
import 'package:catatcuan_mobile/features/produk/product_list.dart';
import 'package:catatcuan_mobile/features/produk/detail_product.dart';
import 'package:catatcuan_mobile/features/settings/settings_page.dart';
import 'package:catatcuan_mobile/features/pelanggan/customer_list.dart';
import 'package:catatcuan_mobile/features/pelanggan/add_customer.dart';
import 'package:catatcuan_mobile/features/pelanggan/customer_detail.dart';
import 'package:catatcuan_mobile/features/penjualan/pos_cashier.dart';
import 'package:catatcuan_mobile/features/penjualan/checkout_page.dart';
import 'package:catatcuan_mobile/features/penjualan/receipt_page.dart';
import 'package:catatcuan_mobile/features/hutang/hutang_list.dart';
import 'package:catatcuan_mobile/features/hutang/insert_hutang.dart';
import 'package:catatcuan_mobile/features/hutang/detail_hutang.dart';
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InsertProductPage(initialBarcode: extra?['barcode'] as String?);
        },
      ),
      GoRoute(
        path: '/produk/detail',
        builder: (context, state) {
          final product = state.extra as Map<String, dynamic>;
          return DetailProductPage(product: product);
        },
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
        builder: (context, state) => const HutangListPage(),
      ),
      GoRoute(
        path: '/hutang/tambah',
        builder: (context, state) => const InsertHutangPage(),
      ),
      GoRoute(
        path: '/hutang/detail',
        builder: (context, state) {
          final hutangData = state.extra as Map<String, dynamic>;
          return DetailHutangPage(initialData: hutangData);
        },
      ),
      GoRoute(
        path: '/pelanggan',
        builder: (context, state) => const CustomerListPage(),
      ),
      GoRoute(
        path: '/pelanggan/add',
        builder: (context, state) => const AddCustomerPage(),
      ),
      GoRoute(
        path: '/pelanggan/detail',
        builder: (context, state) {
          final customer = state.extra as Map<String, dynamic>;
          return CustomerDetailPage(customer: customer);
        },
      ),
      GoRoute(
        path: '/transaksi/pos',
        builder: (context, state) => const PosCashierPage(),
      ),
      GoRoute(
        path: '/transaksi/checkout',
        builder: (context, state) {
          final rawCart = state.extra as Map;
          final cartData = rawCart.map((k, v) => MapEntry(k as String, (v as num).toInt()));
          return CheckoutPage(initialCart: cartData);
        },
      ),
      GoRoute(
        path: '/transaksi/receipt',
        builder: (context, state) {
          final transactionData = state.extra as Map<String, dynamic>;
          return ReceiptPage(transactionData: transactionData);
        },
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
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
