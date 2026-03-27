import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/settings_preferences_service.dart';
import 'package:catatcuan_mobile/core/services/stats_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _statsService = StatsService();
  final _cache = DataCacheService.instance;

  StatsPeriod _selectedPeriod = StatsPeriod.bulanan;
  bool _isLoading = true;
  StatsSummary? _stats;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadDefaultPeriod();
  }

  Future<void> _loadDefaultPeriod() async {
    final defaultPeriod = await SettingsPreferencesService.getDefaultPeriod();
    if (!mounted) return;

    setState(() {
      _selectedPeriod = SettingsPreferencesService.getStatsPeriod(defaultPeriod);
    });

    await _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (_cache.warungId == null) return;
    setState(() => _isLoading = true);
    try {
      final stats = await _statsService.getStats(
        warungId: _cache.warungId!,
        period: _selectedPeriod,
      );
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) => _currencyFormat.format(amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildPeriodFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _stats == null
                    ? const Center(child: Text('Gagal memuat data'))
                    : RefreshIndicator(
                        onRefresh: _fetchStats,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKPIGrid(),
                              const SizedBox(height: 24),
                              _buildTrendChart(),
                              const SizedBox(height: 24),
                              _buildCashflowChart(),
                              const SizedBox(height: 24),
                              _buildInsightCard(),
                              const SizedBox(height: 24),
                              _buildTopProducts(),
                              const SizedBox(height: 40),
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
      height: 110,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stats',
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
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: StatsPeriod.values.map((p) {
            final isSelected = _selectedPeriod == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  _getPeriodLabel(p),
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Poppins',
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriod = p);
                    _fetchStats();
                  }
                },
                selectedColor: AppTheme.primary,
                backgroundColor: const Color(0xFFF3F4F6),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getPeriodLabel(StatsPeriod p) {
    switch (p) {
      case StatsPeriod.harian: return 'Harian';
      case StatsPeriod.mingguan: return 'Mingguan';
      case StatsPeriod.bulanan: return 'Bulanan';
      case StatsPeriod.triwulanan: return 'Triwulanan';
    }
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildKPICard('Omzet', _stats!.omzet, _stats!.omzetDelta, AppTheme.primary),
        _buildKPICard('Profit', _stats!.profit, _stats!.profitDelta, const Color(0xFFEAA220)),
        _buildKPICard('Pengeluaran', _stats!.pengeluaran, _stats!.pengeluaranDelta, const Color(0xFFDC2626)),
        _buildKPICard('Net Cashflow', _stats!.netCashflow, _stats!.netCashflowDelta, const Color(0xFF2A5C99)),
      ],
    );
  }

  Widget _buildKPICard(String title, double value, double delta, Color color) {
    final isPositive = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(value),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? const Color(0xFF13B158) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 2),
              Text(
                '${delta.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? const Color(0xFF13B158) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Penjualan & Profit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= _stats!.trendData.length) return const SizedBox();
                        // Show labels selectively to avoid clutter
                        if (_selectedPeriod == StatsPeriod.bulanan) {
                          if (idx % 5 != 0) return const SizedBox();
                        }
                        return Text(
                          _stats!.trendData[idx].label,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _stats!.trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value1)).toList(),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  LineChartBarData(
                    spots: _stats!.trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value2)).toList(),
                    isCurved: true,
                    color: const Color(0xFFEAA220),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend([
            _LegendItem('Omzet', AppTheme.primary),
            _LegendItem('Profit', const Color(0xFFEAA220)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCashflowChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arus Kas Masuk vs Keluar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= _stats!.cashflowData.length) return const SizedBox();
                        if (_selectedPeriod == StatsPeriod.bulanan) {
                          if (idx % 5 != 0) return const SizedBox();
                        }
                        return Text(
                          _stats!.cashflowData[idx].label,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _stats!.cashflowData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(toY: e.value.value1, color: AppTheme.primary, width: 6),
                      BarChartRodData(toY: e.value.value2, color: const Color(0xFFDC2626), width: 6),
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend([
            _LegendItem('Kas Masuk', AppTheme.primary),
            _LegendItem('Kas Keluar', const Color(0xFFDC2626)),
          ]),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Insight Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem('Waktu Teramai', _stats!.busiestPeriod),
          _buildInsightItem('Rata-rata Transaksi', _formatCurrency(_stats!.averageTransaction)),
          _buildInsightItem('Pembayaran Tunai', '${_stats!.tunaiPercentage.toStringAsFixed(1)}%'),
          _buildInsightItem('Pembayaran Hutang', '${_stats!.hutangPercentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produk Terlaris',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        if (_stats!.topProducts.isEmpty)
          const Text('Belum ada data', style: TextStyle(color: Colors.grey))
        else
          ..._stats!.topProducts.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1EDD8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                    Text(
                      '${p.quantity} terjual',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildLegend(List<_LegendItem> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(item.label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}
