import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BukuKasPage extends StatefulWidget {
  const BukuKasPage({super.key});

  @override
  State<BukuKasPage> createState() => _BukuKasPageState();
}

class _BukuKasPageState extends State<BukuKasPage> {
  final _supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;

  bool isLoading = false;
  List<Map<String, dynamic>> bukuKasItems = [];
  int _limit = 20;
  bool _hasMore = true;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      if (!loadMore) {
        _limit = 20;
        bukuKasItems = [];
      }

      final warungId = _cache.warungId;
      if (warungId == null) return;

      var query = _supabase
          .from('BUKU_KAS')
          .select('*')
          .eq('warung_id', warungId);

      if (_startDate != null) {
        query = query.gte('tanggal', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        // To include the whole end date, we add 1 day or use the end of the day
        final nextDay = _endDate!.add(const Duration(days: 1));
        query = query.lt('tanggal', nextDay.toIso8601String());
      }

      final response = await query
          .order('tanggal', ascending: false)
          .limit(_limit);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );

      setState(() {
        bukuKasItems = data;
        _hasMore = data.length >= _limit;
        if (loadMore) _limit += 20;
      });
    } catch (e) {
      debugPrint('Error fetching buku kas: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  String _formatCurrency(Object? value) {
    final number = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  String _readString(Map<String, dynamic> item, String key) {
    final value = item[key];
    return value?.toString() ?? '';
  }

  double _readDouble(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in bukuKasItems) {
      final dateKey = _formatDate(_readString(item, 'tanggal'));
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final totalUangWarung = _cache.saldoAwal + _cache.uangKas;
    final groupedItems = _groupItemsByDate();
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(statusBarHeight),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchData(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildFilterAndSummary(totalUangWarung),
                    const SizedBox(height: 24),
                    if (isLoading && bukuKasItems.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (bukuKasItems.isEmpty)
                      _buildEmptyState()
                    else
                      ..._buildGroupedList(groupedItems),

                    if (_hasMore && bukuKasItems.isNotEmpty)
                      _buildLoadMoreButton(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return Container(
      height: statusBarHeight + 88,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Buku Kas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
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
    );
  }

  Widget _buildFilterAndSummary(double totalUangWarung) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildFilterButton(),
          const SizedBox(height: 16),
          _buildSummaryCards(totalUangWarung),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    String label = 'Filter Tanggal';
    if (_startDate != null && _endDate != null) {
      label =
          '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}';
    }

    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            if (_startDate != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _fetchData();
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.close, size: 16, color: AppTheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalUangWarung) {
    return Column(
      children: [
        // Main Total Card - Enlarge padding and text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20), // Increased from 16
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JUMLAH UANG WARUNG (LACI+KAS)',
                      style: TextStyle(
                        fontSize: 14, // Increased from 12
                        fontWeight: FontWeight.w600, // Slightly bolder
                        color: Color(0xCC6B7280),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAmountText(totalUangWarung, isLarge: true),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text(
                    '\$',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Sub-Summary Row
        Row(
          children: [
            _buildSubSummaryCard(
              'JUMLAH UANG LACI',
              _cache.saldoAwal,
              isLeft: true,
            ),
            _buildSubSummaryCard(
              'JUMLAH UANG KAS',
              _cache.uangKas,
              isLeft: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubSummaryCard(
    String title,
    double amount, {
    required bool isLeft,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ), // Increased from 12
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: isLeft ? const Radius.circular(10) : Radius.zero,
            bottomRight: !isLeft ? const Radius.circular(10) : Radius.zero,
          ),
          border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12, // Increased from 10
                fontWeight: FontWeight.w600,
                color: Color(0xCC6B7280),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            _buildAmountText(amount, isLarge: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountText(double amount, {required bool isLarge}) {
    final parts = _formatCurrency(amount).split(' ');
    final symbol = parts[0];
    final value = parts.sublist(1).join(' ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: isLarge ? 14 : 12, // Increased
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 28 : 22, // Increased from 24/18
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
            height: 1.0,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedList(
    Map<String, List<Map<String, dynamic>>> groupedItems,
  ) {
    final List<Widget> widgets = [];
    final sortedDates = groupedItems.keys.toList();

    for (var date in sortedDates) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );

      final items = groupedItems[date]!;
      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  _buildHistoryItem(item),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFD1EDD8),
                    ),
                ],
              );
            }),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final type = _readString(item, 'tipe').toLowerCase();
    final source = _readString(item, 'sumber');
    final amount = _readDouble(item, 'amount');
    final isMasuk = type == 'masuk';

    // Label formatting
    String title = source.replaceAll('_', ' ').toUpperCase();
    final String keterangan = _readString(item, 'keterangan');

    if (source == 'saldo_awal') {
      title = 'SALDO AWAL';
      if (keterangan.startsWith('[UANG MASUK')) title = 'UANG MASUK';
      if (keterangan.startsWith('[UANG KELUAR')) title = 'UANG KELUAR';
      if (keterangan.startsWith('[TRANSFER')) title = 'TRANSFER SALDO';
      if (keterangan.startsWith('[PENYESUAIAN')) title = 'PENYESUAIAN SALDO';
    }
    if (source == 'manual_masuk') title = 'UANG MASUK';
    if (source == 'manual_keluar') title = 'UANG KELUAR';
    if (source == 'transfer') title = 'TRANSFER SALDO';
    if (source == 'adjustment') title = 'PENYESUAIAN SALDO';

    if (source == 'penjualan') title = 'TRANSAKSI PENJUALAN';
    if (source == 'pengeluaran') title = 'PENGELUARAN';
    if (source == 'hutang_bayar') title = 'PEMBAYARAN HUTANG';

    return InkWell(
      onTap: () {
        // Placeholder for detail
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1EDD8)),
              ),
              child: Icon(
                isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                color: isMasuk ? AppTheme.primary : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8BD00),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'UANG ${_cache.warungName?.toUpperCase() ?? "WARUNG"} ➔ ${_formatCurrency(item['saldo_setelah'])}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (keterangan.isNotEmpty)
                    Text(
                      keterangan,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${isMasuk ? "+" : "-"}${_formatCurrency(amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isMasuk ? AppTheme.primary : Colors.red,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat kas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () => _fetchData(loadMore: true),
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Load More',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return SizedBox(
      width: 80,
      height: 80,
      child: FloatingActionButton(
        onPressed: _showPopupOptions,
        backgroundColor: AppTheme.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 42),
      ),
    );
  }

  void _showPopupOptions() {
    bool isTransaksiExpanded = true;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPopupSectionTitle(
                  'TRANSAKSI',
                  isOpen: isTransaksiExpanded,
                  onTap: () {
                    setModalState(() {
                      isTransaksiExpanded = !isTransaksiExpanded;
                    });
                  },
                ),
                if (isTransaksiExpanded) ...[
                  _buildPopupItem(
                    icon: Icons.call_received,
                    title: 'UANG MASUK',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await context.push('/buku-kas/uang-masuk');
                      if (result == true) _fetchData();
                    },
                  ),
                  _buildPopupItem(
                    icon: Icons.call_made,
                    title: 'UANG KELUAR',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await context.push(
                        '/buku-kas/uang-keluar',
                      );
                      if (result == true) _fetchData();
                    },
                  ),
                ],
                _buildPopupSectionTitle(
                  'TRANSFER/PEMINDAHAN',
                  isOpen: false,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await context.push('/buku-kas/transfer');
                    if (result == true) _fetchData();
                  },
                ),
                _buildPopupSectionTitle(
                  'PENYESUAIAN SALDO',
                  isOpen: false,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await context.push('/buku-kas/adjustment');
                    if (result == true) _fetchData();
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopupSectionTitle(
    String title, {
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontFamily: 'Poppins',
              ),
            ),
            Icon(
              isOpen ? Icons.arrow_drop_down : Icons.arrow_right,
              color: AppTheme.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: const Color(0xFFEEEEEE).withValues(alpha: 0.5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1EDD8)),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
