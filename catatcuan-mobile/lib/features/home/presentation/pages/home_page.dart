import 'dart:async';

import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/push_notification_service.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:catatcuan_mobile/core/utils/product_stock_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const String _customerServicePhone = '6287825782889';
  static const int _lowStockThreshold = 3;
  static const SystemUiOverlayStyle _homeOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0xFF50C878),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  final supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;
  static final RegExp _sourceTagPattern = RegExp(
    r'^\[Sumber:\s*[^\]]+\]\s*',
    caseSensitive: false,
  );
  Timer? _statusCheckTimer;
  bool _isRedirectingBlockedUser = false;
  bool isLoading = true;
  String? userName;
  String? warungName;
  double omzet = 0;
  double profit = 0;
  double pengeluaran = 0;
  double totalSaldoWarung = 0;
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> stockAlerts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyHomeSystemUi();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _ensureActiveUserStatus(showMessage: false);
    });
    _fetchData();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyHomeSystemUi();
      _ensureActiveUserStatus();
    }
  }

  void _applyHomeSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(_homeOverlayStyle);
  }

  Future<void> _openCustomerServiceWhatsApp() async {
    const message = 'Halo CatatCuan, saya butuh bantuan penggunaan aplikasi.';
    final uri = Uri.parse(
      'https://wa.me/$_customerServicePhone?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      AppToast.showError(
        context,
        'WhatsApp tidak bisa dibuka di perangkat ini',
      );
    }
  }

  void _updateStockAlerts() {
    final alerts =
        _cache.products
            .where((product) {
              return ProductStockHelper.isLowStock(
                product['stok_saat_ini'],
                threshold: _lowStockThreshold,
              );
            })
            .map((product) {
              final stock = ProductStockHelper.parseStock(product['stok_saat_ini']);
              final satuan = (product['satuan'] as String?) ?? 'PCS';
              final productName =
                  (product['nama_produk'] as String?) ?? 'Produk';

              return {
                'name': productName,
                'stock': stock,
                'unit': satuan,
                'message': stock == 0
                    ? 'Produk habis. Segera stok ulang.'
                    : 'Stok tinggal $stock $satuan. Segera beli lagi.',
              };
            })
            .toList()
          ..sort((a, b) {
            final stockA = a['stock'] as int? ?? 0;
            final stockB = b['stock'] as int? ?? 0;
            return stockA.compareTo(stockB);
          });

    stockAlerts = alerts;
  }

  void _showNotificationSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Notifikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                if (stockAlerts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Belum ada notifikasi untuk stok produk.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: stockAlerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final alert = stockAlerts[index];
                        final stock = alert['stock'] as int? ?? 0;
                        final isOutOfStock = stock == 0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOutOfStock
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFFFF7D6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isOutOfStock
                                      ? Icons.error_outline
                                      : Icons.warning_amber_rounded,
                                  color: isOutOfStock
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['name'] as String? ?? 'Produk',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alert['message'] as String? ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureActiveUserStatus({bool showMessage = true}) async {
    if (_isRedirectingBlockedUser) {
      return false;
    }

    final userId = await SessionService.getUserId();
    if (userId == null) {
      return false;
    }

    try {
      final user = await supabase
          .from('USERS')
          .select('status')
          .eq('id', userId)
          .maybeSingle();

      final status = user?['status'] as String? ?? 'inactive';
      if (status == 'active') {
        return true;
      }

      _isRedirectingBlockedUser = true;
      await PushNotificationService.instance.unregisterCurrentDevice();
      await SessionService.logout();

      if (!mounted) {
        return false;
      }

      if (showMessage) {
        if (status == 'suspended') {
          AppToast.showError(
            context,
            'Akun Anda diblokir. Silakan hubungi admin.',
          );
        } else {
          AppToast.showInfo(
            context,
            'Akun Anda dinonaktifkan. Silakan login lagi setelah diaktifkan.',
          );
        }
      }

      context.go('/login');
      return false;
    } catch (e) {
      debugPrint('Error checking user status: $e');
      return true;
    }
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final isAllowed = await _ensureActiveUserStatus();
      if (!isAllowed) return;

      final warungId = _cache.warungId;
      if (warungId == null) return;

      // 1. Refresh cache from DB to ensure accurate balances
      final userId = await SessionService.getUserId();
      if (userId != null) {
        await _cache.refreshWarungData(userId);
      }
      await _cache.refreshProducts();

      userName = _cache.userName;
      warungName = _cache.warungName;
      _updateStockAlerts();

      // LOGIKA KEUANGAN: Uang Warung = Saldo Awal + Akumulasi Kas + Kas Operasional
      totalSaldoWarung =
          _cache.saldoAwal + _cache.uangKas + _cache.uangKasOperasional;

      final now = DateTime.now();
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();
      final todayEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toUtc().toIso8601String();

      // 2. Today's stats (Omzet & Profit)
      final todaySales = await supabase
          .from('PENJUALAN')
          .select('total_amount, profit')
          .eq('warung_id', warungId)
          .gte('tanggal', todayStart)
          .lte('tanggal', todayEnd);

      double todayOmzet = 0;
      double todayProfit = 0;
      for (final sale in todaySales) {
        todayOmzet += (sale['total_amount'] as num?)?.toDouble() ?? 0;
        todayProfit += (sale['profit'] as num?)?.toDouble() ?? 0;
      }
      omzet = todayOmzet;
      profit = todayProfit;

      // 3. Today's stats (Pengeluaran)
      final todayExpenses = await supabase
          .from('PENGELUARAN')
          .select('amount')
          .eq('warung_id', warungId)
          .gte('tanggal', todayStart)
          .lte('tanggal', todayEnd);

      double todayPengeluaran = 0;
      for (final exp in todayExpenses) {
        todayPengeluaran += (exp['amount'] as num?)?.toDouble() ?? 0;
      }
      pengeluaran = todayPengeluaran;

      // 4. Real-time Transactions from PENJUALAN and PENGELUARAN
      final sales = await supabase
          .from('PENJUALAN')
          .select('id, total_amount, tanggal')
          .eq('warung_id', warungId)
          .order('tanggal', ascending: false)
          .limit(5);

      final expenses = await supabase
          .from('PENGELUARAN')
          .select(
            'id, amount, tanggal, keterangan, KATEGORI_PENGELUARAN(nama_kategori)',
          )
          .eq('warung_id', warungId)
          .order('tanggal', ascending: false)
          .limit(5);

      // Get count for transaction numbering
      final countRes = await supabase
          .from('PENJUALAN')
          .select('id')
          .eq('warung_id', warungId);
      final totalSalesCount = (countRes as List).length;

      final List<Map<String, dynamic>> combined = [];
      for (int i = 0; i < sales.length; i++) {
        final s = sales[i];
        combined.add({
          'type': 'sale',
          'id': s['id'],
          'title': 'Transaksi #${(totalSalesCount - i).toString()}',
          'amount': (s['total_amount'] as num).toDouble(),
          'time': DateTime.parse(s['tanggal'] as String).toLocal(),
        });
      }
      for (var e in expenses) {
        final expenseNote = (e['keterangan'] as String? ?? '')
            .replaceFirst(_sourceTagPattern, '')
            .trim();
        combined.add({
          'type': 'expense',
          'id': e['id'],
          'title': expenseNote.isNotEmpty
              ? expenseNote
              : ((e['KATEGORI_PENGELUARAN']
                            as Map<String, dynamic>?)?['nama_kategori']
                        as String? ??
                    'Pengeluaran'),
          'amount': (e['amount'] as num).toDouble(),
          'time': DateTime.parse(e['tanggal'] as String).toLocal(),
        });
      }

      // Sort by time descending
      combined.sort(
        (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
      );
      recentTransactions = combined.take(5).toList();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _homeOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 272,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF50C878), Color(0xFF27623B)],
                            stops: [0.0, 0.66],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SizedBox(height: statusBarHeight + 12),
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildStatsCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildSalesBanner(),
                        const SizedBox(height: 0),
                        _buildMainMenu(),
                        const SizedBox(height: 32),
                        _buildRecentTransactions(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset('assets/logo.png', width: 40, height: 40),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  userName ?? '...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _showNotificationSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  if (stockAlerts.isNotEmpty)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            stockAlerts.length > 99
                                ? '99+'
                                : stockAlerts.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _openCustomerServiceWhatsApp,
              child: Transform.translate(
                offset: const Offset(6, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.support_agent_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Pusat\nBantuan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8BD00),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Text(
                'Hari ini',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatItem(
                    'Omzet Penjualan',
                    omzet,
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF2A5C99),
                    borderRight: true,
                    borderBottom: true,
                  ),
                  _buildStatItem(
                    'Profit Penjualan',
                    profit,
                    Icons.trending_up_outlined,
                    AppTheme.primary,
                    borderBottom: true,
                  ),
                ],
              ),
              Row(
                children: [
                  _buildStatItem(
                    'Pengeluaran',
                    pengeluaran,
                    Icons.output_rounded,
                    const Color(0xFFDC2626),
                    borderRight: true,
                  ),
                  _buildStatItem(
                    'Uang Warung',
                    totalSaldoWarung,
                    Icons.savings_outlined,
                    const Color(0xFFF8BD00),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    double value,
    IconData icon,
    Color iconColor, {
    bool borderRight = false,
    bool borderBottom = false,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    final formatted = currencyFormat.format(value.abs());
    final parts = formatted.split('.');
    final mainVal = parts.isNotEmpty ? parts[0] : '0';
    final subVal = parts.length > 1 ? '.${parts.sublist(1).join('.')}' : '';

    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            right: borderRight
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
            bottom: borderBottom
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 2),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          mainVal,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                            height: 1.0,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (subVal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              subVal,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                                height: 1.0,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Opacity(
                      opacity: 0,
                      child: Padding(
                        padding: EdgeInsets.only(top: 2, left: 2),
                        child: Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesBanner() {
    return GestureDetector(
      onTap: () async {
        final result = await context.push('/transaksi/pos');
        if (result == true) _fetchData();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD1EDD8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/main-page/transaction.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Transaksi',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Text(
                  'Penjualan',
                  style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 30,
      childAspectRatio: 0.85,
      children: [
        _buildMenuItem(
          'Produk',
          'assets/main-page/icon/package.png',
          () => context.push('/produk'),
        ),
        _buildMenuItem(
          'Pengeluaran',
          'assets/main-page/icon/wallet.png',
          () async {
            await context.push('/pengeluaran');
            _fetchData();
          },
        ),
        _buildMenuItem(
          'Buku Kas',
          'assets/main-page/icon/kas.png',
          () => context.push('/buku-kas'),
        ),
        _buildMenuItem(
          'Hutang',
          'assets/main-page/icon/hutang.png',
          () => context.push('/hutang'),
        ),
        _buildMenuItem(
          'Pelanggan',
          'assets/main-page/icon/customer.png',
          () => context.push('/pelanggan'),
        ),
        _buildMenuItem(
          'Laporan',
          'assets/main-page/icon/report.png',
          () => context.push('/laporan'),
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD1EDD8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 65,
                    height: 65,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (recentTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Belum ada transaksi')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = recentTransactions[index];
              final isSale = tx['type'] == 'sale';

              final borderColor = isSale
                  ? const Color(0xFFD1EDD8)
                  : const Color(0xFFDC2626);
              final iconColor = isSale
                  ? AppTheme.primary
                  : const Color(0xFFDC2626);

              final formatCurrency = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              );
              final amountStr = formatCurrency.format(
                (tx['amount'] as num).abs(),
              );

              // Date formatting: Hari, Tgl (for expenses) or HH.mm (for sales)
              String timeDisplay;
              if (!isSale) {
                timeDisplay = DateFormat(
                  'EEEE, d MMM',
                  'id_ID',
                ).format(tx['time'] as DateTime);
              } else {
                timeDisplay = DateFormat(
                  'HH.mm',
                ).format(tx['time'] as DateTime);
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: iconColor, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              isSale
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                tx['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeDisplay,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${isSale ? '+' : '-'}$amountStr',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home_rounded,
            'Beranda',
            true,
            () => context.go('/home'),
          ),
          _buildNavItem(
            Icons.inventory_2_outlined,
            'Produk',
            false,
            () => context.push('/produk'),
          ),
          GestureDetector(
            onTap: () async {
              final res = await context.push('/transaksi/pos');
              if (res == true) _fetchData();
            },
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF50C878),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF50C878).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 36, color: Colors.white),
              ),
            ),
          ),
          _buildNavItem(
            Icons.bar_chart_outlined,
            'Stats',
            false,
            () => context.push('/stats'),
          ),
          _buildNavItem(
            Icons.settings_outlined,
            'Setting',
            false,
            () => context.push('/setting'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.primary : Colors.black,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppTheme.primary : Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
