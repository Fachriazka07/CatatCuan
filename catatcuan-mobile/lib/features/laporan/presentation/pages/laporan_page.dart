import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/laporan_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum ReportType { finance, sales, expense, cashBook, debt }

extension ReportTypeX on ReportType {
  String get title {
    switch (this) {
      case ReportType.finance:
        return 'Ringkasan Keuangan';
      case ReportType.sales:
        return 'Laporan Penjualan';
      case ReportType.expense:
        return 'Laporan Pengeluaran';
      case ReportType.cashBook:
        return 'Laporan Buku Kas';
      case ReportType.debt:
        return 'Laporan Hutang/Piutang';
    }
  }

  String get description {
    switch (this) {
      case ReportType.finance:
        return 'Omzet, profit, expense, neto';
      case ReportType.sales:
        return 'Daftar transaksi dan total jual';
      case ReportType.expense:
        return 'Daftar biaya dan kategori';
      case ReportType.cashBook:
        return 'Mutasi kas masuk dan keluar';
      case ReportType.debt:
        return 'Tagihan, pembayaran, sisa';
    }
  }
}

class _ReportSummaryData {
  const _ReportSummaryData({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final double amount;
  final String subtitle;
  final String status;
}

class _ReportMetricData {
  const _ReportMetricData({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;
}

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _laporanService = LaporanService();
  final _cache = DataCacheService.instance;

  String _selectedPeriodLabel = 'Bulan ini';
  String _selectedPeriodKey = 'bulan_ini';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  ReportType _selectedReportType = ReportType.finance;

  @override
  void initState() {
    super.initState();
    _setPeriod('bulan_ini', 'Bulan ini');
  }

  void _setPeriod(String periodKey, String label) {
    if (periodKey == 'custom') {
      _selectCustomDate();
      return;
    }

    final now = DateTime.now();
    setState(() {
      _selectedPeriodKey = periodKey;
      _selectedPeriodLabel = label;
      if (periodKey == 'hari_ini') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (periodKey == 'minggu_ini') {
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (periodKey == 'bulan_ini') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    });
    _fetchReport();
  }

  Future<void> _selectCustomDate() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriodKey = 'custom';
        _selectedPeriodLabel = 'Custom';
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    if (_cache.warungId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await _laporanService.getLaporanSummary(
        warungId: _cache.warungId!,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching report: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatCount(int count, {String? suffix}) {
    final formatted = NumberFormat.decimalPattern('id_ID').format(count);
    if (suffix == null || suffix.isEmpty) {
      return formatted;
    }
    return '$formatted $suffix';
  }

  double _getReportAmount(String key) {
    return (_reportData[key] as num?)?.toDouble() ?? 0;
  }

  int _getReportCount(String key) {
    return (_reportData[key] as num?)?.toInt() ?? 0;
  }

  List<Map<String, dynamic>> _getReportList(String key) {
    return List<Map<String, dynamic>>.from(_reportData[key] as List? ?? const []);
  }

  _ReportSummaryData _getSummaryData() {
    switch (_selectedReportType) {
      case ReportType.finance:
        final amount = _getReportAmount('laba_bersih');
        return _ReportSummaryData(
          title: 'Laba Bersih',
          amount: amount,
          subtitle: 'Profit penjualan - pengeluaran',
          status: amount >= 0 ? 'Positif' : 'Perlu perhatian',
        );
      case ReportType.sales:
        final jumlahTransaksi = _getReportCount('jumlah_transaksi');
        return _ReportSummaryData(
          title: 'Total Penjualan',
          amount: _getReportAmount('penjualan'),
          subtitle: 'Akumulasi omzet pada periode ini',
          status: jumlahTransaksi > 0
              ? '${_formatCount(jumlahTransaksi)} transaksi'
              : 'Belum ada transaksi',
        );
      case ReportType.expense:
        final jumlahPengeluaran = _getReportCount('jumlah_pengeluaran');
        return _ReportSummaryData(
          title: 'Total Pengeluaran',
          amount: _getReportAmount('pengeluaran'),
          subtitle: 'Seluruh biaya yang tercatat pada periode ini',
          status: jumlahPengeluaran > 0
              ? '${_formatCount(jumlahPengeluaran)} catatan'
              : 'Belum ada pengeluaran',
        );
      case ReportType.cashBook:
        final amount = _getReportAmount('arus_kas_bersih');
        return _ReportSummaryData(
          title: 'Arus Kas Bersih',
          amount: amount,
          subtitle: 'Kas masuk - kas keluar',
          status: amount >= 0 ? 'Kas bertambah' : 'Kas berkurang',
        );
      case ReportType.debt:
        final tagihanAktif = _getReportCount('jumlah_tagihan_aktif');
        return _ReportSummaryData(
          title: 'Sisa Hutang/Piutang',
          amount: _getReportAmount('total_tagihan_sisa'),
          subtitle: 'Sisa piutang + sisa hutang pada periode ini',
          status: tagihanAktif > 0
              ? '${_formatCount(tagihanAktif)} tagihan aktif'
              : 'Semua lunas',
        );
    }
  }

  List<_ReportMetricData> _getMetricData() {
    switch (_selectedReportType) {
      case ReportType.finance:
        return [
          _ReportMetricData(
            title: 'Penjualan',
            value: _formatCurrency(_getReportAmount('penjualan')),
            color: const Color(0xFF2A5C99),
          ),
          _ReportMetricData(
            title: 'Profit Penjualan',
            value: _formatCurrency(_getReportAmount('profit_penjualan')),
            color: AppTheme.primary,
          ),
          _ReportMetricData(
            title: 'Pengeluaran',
            value: _formatCurrency(_getReportAmount('pengeluaran')),
            color: const Color(0xFFDC2626),
          ),
          _ReportMetricData(
            title: 'Uang Kas Masuk',
            value: _formatCurrency(_getReportAmount('kas_masuk')),
            color: const Color(0xFFF8BD00),
          ),
        ];
      case ReportType.sales:
        return [
          _ReportMetricData(
            title: 'Penjualan Tunai',
            value: _formatCurrency(_getReportAmount('penjualan_tunai')),
            color: const Color(0xFF2A5C99),
          ),
          _ReportMetricData(
            title: 'Penjualan Hutang',
            value: _formatCurrency(_getReportAmount('penjualan_hutang')),
            color: AppTheme.primary,
          ),
          _ReportMetricData(
            title: 'Profit Penjualan',
            value: _formatCurrency(_getReportAmount('profit_penjualan')),
            color: const Color(0xFFF8BD00),
          ),
          _ReportMetricData(
            title: 'Jumlah Transaksi',
            value: _formatCount(_getReportCount('jumlah_transaksi')),
            color: const Color(0xFF7C3AED),
          ),
        ];
      case ReportType.expense:
        return [
          _ReportMetricData(
            title: 'Total Pengeluaran',
            value: _formatCurrency(_getReportAmount('pengeluaran')),
            color: const Color(0xFFDC2626),
          ),
          _ReportMetricData(
            title: 'Jumlah Catatan',
            value: _formatCount(_getReportCount('jumlah_pengeluaran')),
            color: const Color(0xFF7C3AED),
          ),
          _ReportMetricData(
            title: 'Rata-rata',
            value: _formatCurrency(_getReportAmount('rata_rata_pengeluaran')),
            color: const Color(0xFF2A5C99),
          ),
          _ReportMetricData(
            title: 'Pengeluaran Terbesar',
            value: _formatCurrency(_getReportAmount('pengeluaran_terbesar')),
            color: const Color(0xFFF8BD00),
          ),
        ];
      case ReportType.cashBook:
        return [
          _ReportMetricData(
            title: 'Kas Masuk',
            value: _formatCurrency(_getReportAmount('kas_masuk')),
            color: AppTheme.primary,
          ),
          _ReportMetricData(
            title: 'Kas Keluar',
            value: _formatCurrency(_getReportAmount('kas_keluar')),
            color: const Color(0xFFDC2626),
          ),
          _ReportMetricData(
            title: 'Arus Kas Bersih',
            value: _formatCurrency(_getReportAmount('arus_kas_bersih')),
            color: const Color(0xFF2A5C99),
          ),
          _ReportMetricData(
            title: 'Jumlah Mutasi',
            value: _formatCount(_getReportCount('jumlah_mutasi_kas')),
            color: const Color(0xFFF8BD00),
          ),
        ];
      case ReportType.debt:
        return [
          _ReportMetricData(
            title: 'Total Piutang',
            value: _formatCurrency(_getReportAmount('total_piutang')),
            color: AppTheme.primary,
          ),
          _ReportMetricData(
            title: 'Total Hutang',
            value: _formatCurrency(_getReportAmount('total_hutang')),
            color: const Color(0xFFDC2626),
          ),
          _ReportMetricData(
            title: 'Sisa Piutang',
            value: _formatCurrency(_getReportAmount('total_piutang_sisa')),
            color: const Color(0xFF2A5C99),
          ),
          _ReportMetricData(
            title: 'Jatuh Tempo',
            value: _formatCount(_getReportCount('jumlah_jatuh_tempo')),
            color: const Color(0xFFF8BD00),
          ),
        ];
    }
  }

  void _showExportMessage(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export $format untuk ${_selectedReportType.title} sedang disiapkan.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      )
                    else ...[
                      _buildMainSummaryCard(),
                      const SizedBox(height: 24),
                      _buildStatsGridCard(),
                      const SizedBox(height: 32),
                      _buildReportTypeList(),
                      const SizedBox(height: 32),
                      _buildDynamicDetailSection(),
                      const SizedBox(height: 32),
                      _buildExportActions(),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Laporan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'PERIODE : ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: Color(0xFF2C2C2C),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            String key = '';
            if (value == 'Hari ini') key = 'hari_ini';
            if (value == 'Minggu ini') key = 'minggu_ini';
            if (value == 'Bulan ini') key = 'bulan_ini';
            if (value == 'Custom') key = 'custom';
            _setPeriod(key, value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Hari ini', child: Text('Hari ini')),
            const PopupMenuItem(value: 'Minggu ini', child: Text('Minggu ini')),
            const PopupMenuItem(value: 'Bulan ini', child: Text('Bulan ini')),
            const PopupMenuItem(value: 'Custom', child: Text('Custom')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedPeriodLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF13B158),
                size: 28,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainSummaryCard() {
    final summary = _getSummaryData();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13B158), Color(0xFF0E8A44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(summary.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${DateFormat('d MMM', 'id_ID').format(_startDate)} - ${DateFormat('d MMM yyyy', 'id_ID').format(_endDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGridCard() {
    final metrics = _getMetricData();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              _buildStatItem(metrics[0], borderRight: true, borderBottom: true),
              _buildStatItem(metrics[1], borderBottom: true),
            ],
          ),
          Row(
            children: [
              _buildStatItem(metrics[2], borderRight: true),
              _buildStatItem(metrics[3]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    _ReportMetricData metric, {
    bool borderRight = false,
    bool borderBottom = false,
  }) {
    return Expanded(
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            right: borderRight
                ? BorderSide(color: Colors.grey.shade200)
                : BorderSide.none,
            bottom: borderBottom
                ? BorderSide(color: Colors.grey.shade200)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              metric.value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: metric.color,
                height: 1.1,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JENIS LAPORAN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ReportType.values.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reportType = ReportType.values[index];
            final isSelected = _selectedReportType == reportType;
            return GestureDetector(
              onTap: () => setState(() => _selectedReportType = reportType),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE6FFE7) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : const Color(0xFFD1EDD8),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportType.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: isSelected
                                  ? AppTheme.primary
                                  : const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reportType.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.chevron_right,
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDynamicDetailSection() {
    switch (_selectedReportType) {
      case ReportType.finance:
      case ReportType.sales:
        return _buildTopProductsSection();
      case ReportType.expense:
        return _buildExpenseCategorySection();
      case ReportType.cashBook:
        return _buildCashMovementSection();
      case ReportType.debt:
        return _buildDebtSection();
    }
  }

  Widget _buildTopProductsSection() {
    final products = _getReportList('top_produk');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedReportType == ReportType.sales
              ? 'PRODUK PENJUALAN TERATAS'
              : 'PRODUK TERLARIS',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EDD8)),
          ),
          child: products.isEmpty
              ? _buildEmptySectionText('Belum ada data produk pada periode ini')
              : Column(
                  children: List.generate(products.length, (index) {
                    final product = products[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == products.length - 1 ? 0 : 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product['nama'] as String? ?? 'Produk',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          Text(
                            '${product['qty'] ?? 0} terjual',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseCategorySection() {
    final categories = _getReportList('kategori_pengeluaran');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORI PENGELUARAN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EDD8)),
          ),
          child: categories.isEmpty
              ? _buildEmptySectionText('Belum ada kategori pengeluaran')
              : Column(
                  children: List.generate(categories.length, (index) {
                    final category = categories[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == categories.length - 1 ? 0 : 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              category['nama'] as String? ?? 'Tanpa Kategori',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Text(
                            _formatCurrency(
                              (category['amount'] as num?)?.toDouble() ?? 0,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildCashMovementSection() {
    final cashItems = _getReportList('cash_items');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MUTASI KAS TERBARU',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EDD8)),
          ),
          child: cashItems.isEmpty
              ? _buildEmptySectionText('Belum ada mutasi kas')
              : Column(
                  children: List.generate(cashItems.length, (index) {
                    final item = cashItems[index];
                    final isMasuk =
                        (item['type'] as String? ?? '').toLowerCase() == 'masuk';
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == cashItems.length - 1 ? 0 : 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (isMasuk
                                      ? AppTheme.primary
                                      : const Color(0xFFDC2626))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isMasuk
                                  ? AppTheme.primary
                                  : const Color(0xFFDC2626),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String? ?? 'Mutasi Kas',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle'] as String? ??
                                      'Mutasi kas tercatat',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${isMasuk ? '+' : '-'}${_formatCurrency((item['amount'] as num?)?.toDouble() ?? 0)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isMasuk
                                  ? AppTheme.primary
                                  : const Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildDebtSection() {
    final debtItems = _getReportList('debt_items');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TAGIHAN TERATAS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EDD8)),
          ),
          child: debtItems.isEmpty
              ? _buildEmptySectionText('Belum ada data hutang/piutang')
              : Column(
                  children: List.generate(debtItems.length, (index) {
                    final item = debtItems[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == debtItems.length - 1 ? 0 : 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama'] as String? ?? 'Pelanggan',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['jenis'] ?? 'Tagihan'} | ${item['status'] ?? 'Belum lunas'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatCurrency(
                              (item['amount'] as num?)?.toDouble() ?? 0,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2A5C99),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptySectionText(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildExportActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXPORT LAPORAN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedReportType.title,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExportButton(
                label: 'Excel',
                icon: Icons.table_chart_rounded,
                color: AppTheme.primary,
                onTap: () => _showExportMessage('Excel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExportButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFF8BD00),
                onTap: () => _showExportMessage('PDF'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          'Export $label',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
