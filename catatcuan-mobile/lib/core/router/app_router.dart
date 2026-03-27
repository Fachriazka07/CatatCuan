import 'package:catatcuan_mobile/features/buku_kas/adjustment/adjustment_page.dart';
import 'package:catatcuan_mobile/features/buku_kas/buku_kas_page.dart';
import 'package:catatcuan_mobile/features/buku_kas/transaction/uang_keluar_page.dart';
import 'package:catatcuan_mobile/features/buku_kas/transaction/uang_masuk_page.dart';
import 'package:catatcuan_mobile/features/buku_kas/transfer/transfer_page.dart';
import 'package:catatcuan_mobile/features/home/presentation/pages/home_page.dart';
import 'package:catatcuan_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:catatcuan_mobile/features/produk/insert_product.dart';
import 'package:catatcuan_mobile/features/produk/product_list.dart';
import 'package:catatcuan_mobile/features/produk/detail_product.dart';
import 'package:catatcuan_mobile/features/pengeluaran/pengeluaran_list.dart';
import 'package:catatcuan_mobile/features/pengeluaran/insert_pengeluaran.dart';
import 'package:catatcuan_mobile/features/pengeluaran/detail_pengeluaran.dart';
import 'package:catatcuan_mobile/features/settings/settings_page.dart';
import 'package:catatcuan_mobile/features/settings/profile_page.dart';
import 'package:catatcuan_mobile/features/settings/edit_profile_page.dart';
import 'package:catatcuan_mobile/features/settings/warung_detail_page.dart';
import 'package:catatcuan_mobile/features/settings/edit_warung_page.dart';
import 'package:catatcuan_mobile/features/settings/change_password_page.dart';
import 'package:catatcuan_mobile/features/settings/default_period_page.dart';
import 'package:catatcuan_mobile/features/settings/product_categories_page.dart';
import 'package:catatcuan_mobile/features/settings/expense_categories_page.dart';
import 'package:catatcuan_mobile/features/settings/product_units_page.dart';
import 'package:catatcuan_mobile/features/settings/opening_balance_page.dart';
import 'package:catatcuan_mobile/features/settings/about_app_page.dart';
import 'package:catatcuan_mobile/features/settings/privacy_policy_page.dart';
import 'package:catatcuan_mobile/features/settings/notification_settings_page.dart';
import 'package:catatcuan_mobile/core/services/settings_profile_service.dart';
import 'package:catatcuan_mobile/features/pelanggan/customer_list.dart';
import 'package:catatcuan_mobile/features/pelanggan/add_customer.dart';
import 'package:catatcuan_mobile/features/pelanggan/customer_detail.dart';
import 'package:catatcuan_mobile/features/penjualan/pos_cashier.dart';
import 'package:catatcuan_mobile/features/penjualan/checkout_page.dart';
import 'package:catatcuan_mobile/features/penjualan/receipt_page.dart';
import 'package:catatcuan_mobile/features/hutang/hutang_list.dart';
import 'package:catatcuan_mobile/features/hutang/insert_hutang.dart';
import 'package:catatcuan_mobile/features/hutang/detail_hutang.dart';
import 'package:catatcuan_mobile/features/laporan/presentation/pages/laporan_page.dart';
import 'package:catatcuan_mobile/features/stats/presentation/pages/stats_page.dart';
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
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      // Feature Placeholders
      GoRoute(
        path: '/produk',
        builder: (context, state) => const ProductListPage(),
      ),
      GoRoute(
        path: '/produk/add',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InsertProductPage(
            initialBarcode: extra?['barcode'] as String?,
          );
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
        builder: (context, state) => const PengeluaranListPage(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const InsertPengeluaranPage(),
          ),
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final expense = state.extra as Map<String, dynamic>;
              return DetailPengeluaranPage(expense: expense);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/buku-kas',
        builder: (context, state) => const BukuKasPage(),
      ),
      GoRoute(
        path: '/buku-kas/uang-masuk',
        builder: (context, state) => const UangMasukPage(),
      ),
      GoRoute(
        path: '/buku-kas/uang-keluar',
        builder: (context, state) => const UangKeluarPage(),
      ),
      GoRoute(
        path: '/buku-kas/transfer',
        builder: (context, state) => const TransferPage(),
      ),
      GoRoute(
        path: '/buku-kas/adjustment',
        builder: (context, state) => const AdjustmentPage(),
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
          final cartData = rawCart.map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          );
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
        builder: (context, state) => const LaporanPage(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsPage(),
      ),
      GoRoute(
        path: '/setting',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/setting/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/setting/profile/edit',
        builder: (context, state) {
          final data = state.extra as SettingsProfileData;
          return EditProfilePage(initialData: data);
        },
      ),
      GoRoute(
        path: '/setting/warung',
        builder: (context, state) => const WarungDetailPage(),
      ),
      GoRoute(
        path: '/setting/warung/edit',
        builder: (context, state) {
          final data = state.extra as SettingsProfileData;
          return EditWarungPage(initialData: data);
        },
      ),
      GoRoute(
        path: '/setting/password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/setting/default-period',
        builder: (context, state) => const DefaultPeriodPage(),
      ),
      GoRoute(
        path: '/setting/notifications',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/setting/product-categories',
        builder: (context, state) => const ProductCategoriesPage(),
      ),
      GoRoute(
        path: '/setting/expense-categories',
        builder: (context, state) => const ExpenseCategoriesPage(),
      ),
      GoRoute(
        path: '/setting/product-units',
        builder: (context, state) => const ProductUnitsPage(),
      ),
      GoRoute(
        path: '/setting/opening-balance',
        builder: (context, state) => const OpeningBalancePage(),
      ),
      GoRoute(
        path: '/setting/about',
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: '/setting/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
    ],
  );
}
