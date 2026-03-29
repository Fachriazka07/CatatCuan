import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/hutang_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HutangListPage extends StatefulWidget {
  const HutangListPage({super.key});

  @override
  State<HutangListPage> createState() => _HutangListPageState();
}

class _HutangListPageState extends State<HutangListPage> {
  int _selectedTab = 0;
  final _cache = DataCacheService.instance;
  final _hutangService = HutangService();

  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  DateTime? _tryParseSafeDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    final sanitized = raw
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('"', '')
        .trim();

    return DateTime.tryParse(sanitized)?.toLocal();
  }

  DateTime? _tryParseOptionalDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    final sanitized = raw
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('"', '')
        .trim();

    return DateTime.tryParse(sanitized)?.toLocal();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _hutangService.getHutangList(_cache.warungId!);
      setState(() {
        _allData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Track which customer groups are expanded
  final Set<String> _expandedGroups = {};

  List<Map<String, dynamic>> get _filteredData {
    return _allData.where((item) {
      final status = item['status'] as String;
      final jenis = item['jenis'] as String? ?? 'PIUTANG'; // Default fallback

      if (_selectedTab == 0) {
        // Hutang (Kita yang ngutang) & Belum Lunas
        return status != 'lunas' && jenis == 'HUTANG';
      } else if (_selectedTab == 1) {
        // Piutang (Orang ngutang ke kita) & Belum Lunas
        return status != 'lunas' && jenis == 'PIUTANG';
      } else {
        // Lunas
        return status == 'lunas';
      }
    }).toList();
  }

  /// Group filtered data by pelanggan_id (or nama_kontak fallback)
  List<Map<String, dynamic>> get _groupedData {
    final filtered = _filteredData;
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in filtered) {
      final key =
          item['pelanggan_id']?.toString() ??
          item['nama_kontak']?.toString() ??
          'unknown';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    // Build a list of group summaries
    final List<Map<String, dynamic>> groups = [];
    for (final entry in grouped.entries) {
      final items = entry.value;
      final pelanggan = items.first['PELANGGAN'] as Map<String, dynamic>?;
      final name =
          items.first['nama_kontak'] as String? ??
          (pelanggan?['nama'] as String? ?? 'Tanpa Nama');

      double totalAwal = 0;
      double totalTerbayar = 0;
      double totalSisa = 0;
      for (final item in items) {
        totalAwal += (item['amount_awal'] as num?)?.toDouble() ?? 0;
        totalTerbayar += (item['amount_terbayar'] as num?)?.toDouble() ?? 0;
        totalSisa += (item['amount_sisa'] as num?)?.toDouble() ?? 0;
      }

      groups.add({
        'key': entry.key,
        'name': name,
        'total_awal': totalAwal,
        'total_terbayar': totalTerbayar,
        'total_sisa': totalSisa,
        'items': items,
        'count': items.length,
      });
    }

    // Sort groups alphabetically by name
    groups.sort(
      (a, b) => (a['name'] as String).toLowerCase().compareTo(
        (b['name'] as String).toLowerCase(),
      ),
    );
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTabSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : _buildList(currencyFormatter),
              ),
            ],
          ),
          _buildFAB(),
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
            'Hutang & Piutang',
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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabItem(0, 'Hutang', isFirst: true),
            _buildTabItem(1, 'Piutang'),
            _buildTabItem(2, 'Lunas', isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    int index,
    String label, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6FFE7) : Colors.white,
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
              width: 1,
            ),
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Icon(Icons.check, color: AppTheme.primary, size: 18),
              if (isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(NumberFormat formatter) {
    final groups = _groupedData;

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data ${_selectedTab == 0
                  ? "Hutang"
                  : _selectedTab == 1
                  ? "Piutang"
                  : "Lunas"}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(group, formatter);
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, NumberFormat formatter) {
    final String key = group['key'] as String;
    final String name = group['name'] as String;
    final double totalAwal = group['total_awal'] as double;
    final double totalTerbayar = group['total_terbayar'] as double;
    final double totalSisa = group['total_sisa'] as double;
    final List<Map<String, dynamic>> items =
        group['items'] as List<Map<String, dynamic>>;
    final int count = group['count'] as int;
    final bool isExpanded = _expandedGroups.contains(key);
    final double progress = totalAwal > 0
        ? (totalTerbayar / totalAwal).clamp(0.0, 1.0)
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header — summary per pelanggan
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (count == 1) {
                context
                    .push('/hutang/detail', extra: items.first)
                    .then((_) => _fetchData());
              } else {
                setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(key);
                  } else {
                    _expandedGroups.add(key);
                  }
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top row: Avatar + Name/Count + Amount
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD1EDD8),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          name.isNotEmpty
                              ? name.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (count > 1)
                              Row(
                                children: [
                                  Text(
                                    '$count transaksi',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppTheme.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Text(
                        formatter.format(totalAwal),
                        style: TextStyle(
                          color: _selectedTab == 1
                              ? AppTheme.primary
                              : const Color(0xFFF8BD00),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  // Bottom section: amounts or lunas badge
                  if (_selectedTab != 2) ...[
                    const SizedBox(height: 4),
                    _buildAmountRow(
                      _selectedTab == 1 ? 'Diterima' : 'Terbayar',
                      formatter.format(totalTerbayar),
                      AppTheme.primary,
                    ),
                    _buildAmountRow(
                      _selectedTab == 1 ? 'Sisa Piutang' : 'Kekurangan',
                      formatter.format(totalSisa),
                      AppTheme.error,
                    ),
                    const SizedBox(height: 8),
                    _buildProgressBar(progress),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1EDD8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.primary,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LUNAS TERBAYAR',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Expanded sub-items
          if (isExpanded && count > 1) ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFC),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFD1EDD8),
                  ),
                  ...items.map((item) => _buildSubItem(item, formatter)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubItem(Map<String, dynamic> item, NumberFormat formatter) {
    final total = (item['amount_awal'] as num?)?.toDouble() ?? 0;
    final sisa = (item['amount_sisa'] as num?)?.toDouble() ?? 0;
    final catatan = item['catatan'] as String? ?? '';
    final jenis = item['jenis'] as String? ?? 'HUTANG';
    final isPiutang = jenis.toUpperCase() == 'PIUTANG';
    final isLunas = item['status'] == 'lunas';
    final jatuhTempo = _tryParseOptionalDate(item['tanggal_jatuh_tempo']);
    final createdAtDate = _tryParseSafeDate(item['created_at']);
    final createdAt = createdAtDate != null
        ? DateFormat('dd MMM yyyy').format(createdAtDate)
        : '-';

    return InkWell(
      onTap: () async {
        await context.push('/hutang/detail', extra: item);
        _fetchData();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date box with varying color
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPiutang
                    ? const Color(0xFFE6F0FF)
                    : const Color(0xFFE6FFE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPiutang ? Icons.arrow_downward_rounded : Icons.receipt_long,
                color: isPiutang ? Colors.blue : AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    createdAt,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF374151),
                    ),
                  ),
                  if (catatan.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      catatan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  if (jatuhTempo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Jatuh tempo: ${DateFormat('dd MMM yyyy', 'id_ID').format(jatuhTempo)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    isLunas
                        ? (isPiutang ? 'PIUTANG LUNAS' : 'HUTANG LUNAS')
                        : 'Sisa: ${formatter.format(sisa)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: isLunas ? FontWeight.bold : FontWeight.normal,
                      color: isLunas
                          ? AppTheme.primary
                          : (sisa > 0 ? AppTheme.error : AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () async {
          // Navigate to add page
          await context.push('/hutang/tambah');
          _fetchData(); // Refresh list after adding
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppTheme.primary, // Green solid circle
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }
}
