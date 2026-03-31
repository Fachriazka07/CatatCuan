import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengeluaranListPage extends StatefulWidget {
  const PengeluaranListPage({super.key});

  @override
  State<PengeluaranListPage> createState() => _PengeluaranListPageState();
}

class _PengeluaranListPageState extends State<PengeluaranListPage> {
  final _supabase = Supabase.instance.client;
  final _cache = DataCacheService.instance;
  static const Set<String> _availableExpenseIcons = {
    'Kesehatan.png',
    'LainnyaPribadi.png',
    'MakanDapur.png',
    'Pakaian.png',
    'Pendidikan.png',
    'Sedekah.png',
  };
  static final RegExp _sourceTagPattern = RegExp(
    r'^\[Sumber:\s*([^\]]+)\]\s*',
    caseSensitive: false,
  );

  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  double _totalExpenditure = 0;
  String _selectedPeriod = 'Hari ini';
  int _limit = 5;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);

    try {
      final warungId = _cache.warungId;
      if (warungId == null) return;

      final DateTime now = DateTime.now();
      DateTime startDate;

      if (_selectedPeriod == 'Minggu ini') {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
      } else if (_selectedPeriod == 'Bulan ini') {
        startDate = DateTime(now.year, now.month, 1);
      } else {
        // Hari ini
        startDate = DateTime(now.year, now.month, now.day);
      }

      final response = await _supabase
          .from('PENGELUARAN')
          .select('*, KATEGORI_PENGELUARAN(nama_kategori, icon, tipe)')
          .eq('warung_id', warungId)
          .gte('tanggal', startDate.toIso8601String())
          .order('tanggal', ascending: false)
          .limit(_limit);

      final data = List<Map<String, dynamic>>.from(response);

      double total = 0;
      for (var item in data) {
        total += (item['amount'] as num).toDouble();
      }

      setState(() {
        _expenses = data;
        _totalExpenditure = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatExpenseNote(String? note) {
    final cleaned = (note ?? '').replaceFirst(_sourceTagPattern, '').trim();
    return cleaned.isEmpty ? '-' : cleaned;
  }

  String _resolveExpenseIconPath(String? iconName) {
    final normalized = iconName?.trim() ?? '';
    if (_availableExpenseIcons.contains(normalized)) {
      return 'assets/icon/pengeluaran-icon/$normalized';
    }
    return 'assets/icon/produk-icon/Lainya.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchExpenses,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      _buildTotalSection(),
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _buildExpenseList(),
                      if (_expenses.length >= _limit && !_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: _buildLoadMoreButton(),
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF13B158), Color(0xFF3A9B6B)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pengeluaran',
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

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
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
              setState(() => _selectedPeriod = value);
              _fetchExpenses();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Hari ini', child: Text('Hari ini')),
              const PopupMenuItem(
                value: 'Minggu ini',
                child: Text('Minggu ini'),
              ),
              const PopupMenuItem(value: 'Bulan ini', child: Text('Bulan ini')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedPeriod,
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
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pengeluaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: const Color(0xFF1B1F23).withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatCurrency(_totalExpenditure),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_expenses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 100,
        alignment: Alignment.center,
        child: const Text(
          'Belum ada pengeluaran',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _expenses.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 1, color: Color(0xFFD1EDD8)),
        itemBuilder: (context, index) {
          return _buildExpenseItem(_expenses[index]);
        },
      ),
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> item) {
    final cat = item['KATEGORI_PENGELUARAN'] as Map<String, dynamic>?;
    final iconPath = cat?['icon'] as String?;
    final title = cat?['nama_kategori'] as String? ?? 'Lainnya';
    final amount = (item['amount'] as num).toDouble();
    final date = DateTime.parse(item['tanggal'].toString());
    final timeStr = DateFormat('HH:mm').format(date);

    return InkWell(
      onTap: () async {
        final result = await context.push('/pengeluaran/detail', extra: item);
        if (result == true) _fetchExpenses();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 80,
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1EDD8)),
              ),
              child: Center(
                child: Image.asset(
                  _resolveExpenseIconPath(iconPath),
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) =>
                      Image.asset(
                        'assets/icon/produk-icon/Lainya.png',
                        width: 40,
                        height: 40,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF8BD00),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    _formatExpenseNote(item['keterangan'] as String?),
                    maxLines: 1,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-${_formatCurrency(amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFDC2626),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7280).withValues(alpha: 0.8),
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

  Widget _buildLoadMoreButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _limit += 5;
        });
        _fetchExpenses();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1EDD8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Load More',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF13B158),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(bottom: 16, right: 16),
      child: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/pengeluaran/add');
          if (result == true) _fetchExpenses();
        },
        backgroundColor: const Color(0xFF13B158),
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      ),
    );
  }
}
