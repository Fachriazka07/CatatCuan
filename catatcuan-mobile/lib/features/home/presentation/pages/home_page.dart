import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;
  bool isLoading = true;
  String? userName;
  String? warungName;
  double omzet = 0;
  double profit = 0;
  double pengeluaran = 0;
  double saldoWarung = 0;
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      // Get warung data from cache (instant, no network)
      final warungId = _cache.warungId;
      if (warungId == null) return;

      userName = _cache.userName;
      warungName = _cache.warungName;
      saldoWarung = _cache.saldoAwal + _cache.uangKas;

      // Fetch Today's Omzet & Profit directly from PENJUALAN (real-time)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

      final todaySales = await supabase
          .from('PENJUALAN')
          .select('total_amount, profit')
          .eq('warung_id', warungId)
          .gte('tanggal', todayStart)
          .lte('tanggal', todayEnd);

      // Sum up Omzet and Profit from today's transactions
      double todayOmzet = 0;
      double todayProfit = 0;
      for (final sale in todaySales) {
        todayOmzet += (sale['total_amount'] as num?)?.toDouble() ?? 0;
        todayProfit += (sale['profit'] as num?)?.toDouble() ?? 0;
      }
      omzet = todayOmzet;
      profit = todayProfit;

      // Fetch Today's Pengeluaran from PENGELUARAN table
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
      final countRes = await supabase
          .from('PENJUALAN')
          .select('id')
          .eq('warung_id', warungId)
          .count(CountOption.exact);
      final totalSales = countRes.count;

      final sales = await supabase
          .from('PENJUALAN')
          .select('id, total_amount, tanggal')
          .eq('warung_id', warungId)
          .order('tanggal', ascending: false)
          .limit(3);

      final expenses = await supabase
          .from('PENGELUARAN')
          .select('id, amount, tanggal, keterangan, KATEGORI_PENGELUARAN(nama_kategori)')
          .eq('warung_id', warungId)
          .order('tanggal', ascending: false)
          .limit(3);

      final List<Map<String, dynamic>> combined = [];
      for (int i = 0; i < sales.length; i++) {
        final s = sales[i];
        final seqNum = totalSales - i;
        combined.add({
          'type': 'sale',
          'id': s['id'],
          'title': 'Transaksi #${seqNum.toString()}',
          'amount': (s['total_amount'] as num).toDouble(),
          'time': DateTime.parse(s['tanggal'] as String).toLocal(),
        });
      }
      for (var e in expenses) {
        combined.add({
          'type': 'expense',
          'id': e['id'],
          'title': (e['keterangan'] as String?) ?? ((e['KATEGORI_PENGELUARAN'] as Map<String, dynamic>?)?['nama_kategori'] as String? ?? 'Pengeluaran'),
          'amount': -(e['amount'] as num).toDouble(),
          'time': DateTime.parse(e['tanggal'] as String).toLocal(),
        });
      }
      combined.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
      recentTransactions = combined.take(4).toList();

    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
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
                      height: 240,
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
                          const SizedBox(height: 16),
                          _buildHeader(),
                          const SizedBox(height: 24),
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
                      const SizedBox(height: 24),
                      _buildSalesBanner(),
                      const SizedBox(height: 24),
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
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
            ),
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
            // Notification bell (plain icon, no background)
            const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Transform.translate(
              offset: const Offset(16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    Icon(Icons.support_agent_outlined, color: Colors.white, size: 22),
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
                  _buildStatItem('Omzet Penjualan', omzet, Icons.account_balance_wallet_outlined, const Color(0xFF2A5C99), borderRight: true, borderBottom: true),
                  _buildStatItem('Profit Penjualan', profit, Icons.trending_up_outlined, AppTheme.primary, borderBottom: true),
                ],
              ),
              Row(
                children: [
                  _buildStatItem('Pengeluaran', pengeluaran, Icons.receipt_long_outlined, const Color(0xFFE57373), borderRight: true),
                  _buildStatItem('Uang Warung', saldoWarung, Icons.savings_outlined, const Color(0xFFF8BD00)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, double value, IconData icon, Color iconColor, {bool borderRight = false, bool borderBottom = false}) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
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
            right: borderRight ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
            bottom: borderBottom ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title truly centered without icon
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15, // Increased size
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          // Nominal — truly centered around main digit
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min, // Keep row tight
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top for superscript effect
                children: [
                  // The superscript Rp
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 2), // Slightly push down to match top of '0'
                    child: Text(
                      'Rp',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  
                  // Main number block
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end, // Align nominal and sub-nominal bottoms
                    children: [
                      Text(
                        mainVal,
                        style: const TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                          height: 1.0, 
                          fontFamily: 'Poppins',
                        ),
                      ),
                      // Sub digits — primary color
                      if (subVal.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1), 
                          child: Text(
                            subVal,
                            style: const TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.w600, 
                              color: AppTheme.primary,
                              height: 1.0, 
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Invisible Rp to balance the row and keep the main number perfectly centered
                  const Opacity(
                    opacity: 0,
                    child: Padding(
                      padding: EdgeInsets.only(top: 2, left: 2),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 12,
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
      onTap: () => context.push('/transaksi/pos'),
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
            // Transaction image
            Image.asset(
              'assets/main-page/transaction.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            // Text
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
        _buildMenuItem('Produk', 'assets/main-page/icon/package.png', () => context.push('/produk')),
        _buildMenuItem('Pengeluaran', 'assets/main-page/icon/wallet.png', () => context.push('/pengeluaran')),
        _buildMenuItem('Buku Kas', 'assets/main-page/icon/kas.png', () => context.push('/buku-kas')),
        _buildMenuItem('Hutang', 'assets/main-page/icon/hutang.png', () => context.push('/hutang')),
        _buildMenuItem('Pelanggan', 'assets/main-page/icon/customer.png', () => context.push('/pelanggan')),
        _buildMenuItem('Laporan', 'assets/main-page/icon/report.png', () => context.push('/laporan')),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
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
            fontWeight: FontWeight.w600, // Semibold
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
              final borderColor = isSale ? const Color(0xFFD1EDD8) : const Color(0xFFDC2626);
              final iconColor = isSale ? AppTheme.primary : const Color(0xFFDC2626);
              
              // We use NumberFormat with custom properties to enforce the exact layout required by the user
              final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
              final amountStr = formatCurrency.format((tx['amount'] as num).abs());

              // Time formatting
              final timeStr = DateFormat('HH.mm').format(tx['time'] as DateTime);

              return Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                              isSale ? Icons.arrow_upward : Icons.arrow_downward,
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tx['title'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                fontFamily: 'Poppins',
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Poppins',
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${isSale ? '+' : '-'}$amountStr',
                      style: TextStyle(
                        fontSize: 20,
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
          _buildNavItem(Icons.home_rounded, 'Beranda', true, () => context.go('/home')),
          _buildNavItem(Icons.inventory_2_outlined, 'Produk', false, () => context.push('/produk')),
          GestureDetector(
            onTap: () {
              context.push('/transaksi/pos');
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
          _buildNavItem(Icons.bar_chart_outlined, 'Stats', false, () => context.push('/stats')),
          _buildNavItem(Icons.settings_outlined, 'Setting', false, () => context.push('/setting')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? AppTheme.primary : Colors.black, size: 30),
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
