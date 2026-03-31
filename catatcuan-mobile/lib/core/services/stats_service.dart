import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsSummary {
  final double omzet;
  final double profit;
  final double pengeluaran;
  final double netCashflow;
  final double kasMasuk;
  final double kasKeluar;
  final int jumlahTransaksi;
  
  final double omzetDelta; // Percentage
  final double profitDelta;
  final double pengeluaranDelta;
  final double netCashflowDelta;

  final List<ChartDataPoint> trendData; // Omzet & Profit trend
  final List<ChartDataPoint> cashflowData; // Kas Masuk vs Kas Keluar
  
  final List<TopProduct> topProducts;
  final String busiestPeriod; // e.g., "14:00" or "Sabtu"
  final double averageTransaction;
  final double tunaiPercentage;
  final double hutangPercentage;

  StatsSummary({
    required this.omzet,
    required this.profit,
    required this.pengeluaran,
    required this.netCashflow,
    required this.kasMasuk,
    required this.kasKeluar,
    required this.jumlahTransaksi,
    required this.omzetDelta,
    required this.profitDelta,
    required this.pengeluaranDelta,
    required this.netCashflowDelta,
    required this.trendData,
    required this.cashflowData,
    required this.topProducts,
    required this.busiestPeriod,
    required this.averageTransaction,
    required this.tunaiPercentage,
    required this.hutangPercentage,
  });
}

class ChartDataPoint {
  final String label;
  final double value1; // e.g., Omzet or Kas Masuk
  final double value2; // e.g., Profit or Kas Keluar

  ChartDataPoint({
    required this.label,
    required this.value1,
    required this.value2,
  });
}

class TopProduct {
  final String name;
  final int quantity;

  TopProduct({
    required this.name,
    required this.quantity,
  });
}

enum StatsPeriod { harian, mingguan, bulanan, triwulanan }

class StatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _stringValue(Object? value, {String fallback = ''}) {
    final stringValue = value?.toString().trim() ?? '';
    return stringValue.isEmpty ? fallback : stringValue;
  }

  double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _mapList(Object? value) {
    final list = value is List ? value : const [];
    return list
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<StatsSummary> getStats({
    required String warungId,
    required StatsPeriod period,
  }) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime prevStartDate;
    DateTime prevEndDate;

    switch (period) {
      case StatsPeriod.harian:
        startDate = DateTime(now.year, now.month, now.day);
        prevStartDate = startDate.subtract(const Duration(days: 1));
        prevEndDate = prevStartDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        break;
      case StatsPeriod.mingguan:
        // Week starts on Monday
        int weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        prevStartDate = startDate.subtract(const Duration(days: 7));
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
      case StatsPeriod.bulanan:
        startDate = DateTime(now.year, now.month, 1);
        prevStartDate = DateTime(now.year, now.month - 1, 1);
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
      case StatsPeriod.triwulanan:
        startDate = DateTime(now.year, now.month - 2, 1);
        prevStartDate = DateTime(now.year, now.month - 5, 1);
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        break;
    }

    final currentData = await _fetchPeriodData(warungId, startDate, endDate, period);
    final prevData = await _fetchPeriodData(warungId, prevStartDate, prevEndDate, period);

    return _processStats(currentData, prevData, period);
  }

  Future<Map<String, dynamic>> _fetchPeriodData(
    String warungId,
    DateTime start,
    DateTime end,
    StatsPeriod period,
  ) async {
    final startStr = start.toUtc().toIso8601String();
    final endStr = end.toUtc().toIso8601String();

    // 1. Fetch Sales
    final salesRes = await _supabase
        .from('PENJUALAN')
        .select('tanggal, total_amount, profit, payment_method')
        .eq('warung_id', warungId)
        .gte('tanggal', startStr)
        .lte('tanggal', endStr);

    // 2. Fetch Expenses
    final expenseRes = await _supabase
        .from('PENGELUARAN')
        .select('tanggal, amount')
        .eq('warung_id', warungId)
        .gte('tanggal', startStr)
        .lte('tanggal', endStr);

    // 3. Fetch Cashflow
    final kasRes = await _supabase
        .from('BUKU_KAS')
        .select('tipe, amount, tanggal')
        .eq('warung_id', warungId)
        .gte('tanggal', startStr)
        .lte('tanggal', endStr);

    // 4. Fetch Top Products (only for current period to save tokens/time)
    final itemsRes = await _supabase
        .from('PENJUALAN_ITEM')
        .select('nama_produk, quantity, PENJUALAN!inner(warung_id, tanggal)')
        .eq('PENJUALAN.warung_id', warungId)
        .gte('PENJUALAN.tanggal', startStr)
        .lte('PENJUALAN.tanggal', endStr);

    return {
      'sales': salesRes,
      'expenses': expenseRes,
      'cashflow': kasRes,
      'items': itemsRes,
    };
  }

  StatsSummary _processStats(
    Map<String, dynamic> current,
    Map<String, dynamic> prev,
    StatsPeriod period,
  ) {
    // Process Current
    final currentSales = _mapList(current['sales']);
    final currentExpenses = _mapList(current['expenses']);
    final currentKas = _mapList(current['cashflow']);
    final currentItems = _mapList(current['items']);

    double omzet = 0;
    double profit = 0;
    double tunai = 0;
    double hutang = 0;
    for (var s in currentSales) {
      omzet += _doubleValue(s['total_amount']);
      profit += _doubleValue(s['profit']);
      if (s['payment_method'] == 'tunai') {
        tunai += _doubleValue(s['total_amount']);
      } else {
        hutang += _doubleValue(s['total_amount']);
      }
    }

    double pengeluaran = 0;
    for (var e in currentExpenses) {
      pengeluaran += _doubleValue(e['amount']);
    }

    double kasMasuk = 0;
    double kasKeluar = 0;
    for (var k in currentKas) {
      final amt = _doubleValue(k['amount']);
      if (k['tipe'] == 'masuk') {
        kasMasuk += amt;
      } else {
        kasKeluar += amt;
      }
    }

    // Process Previous for Delta
    final prevSales = _mapList(prev['sales']);
    final prevExpenses = _mapList(prev['expenses']);
    final prevKas = _mapList(prev['cashflow']);

    double prevOmzet = 0;
    double prevProfit = 0;
    for (var s in prevSales) {
      prevOmzet += _doubleValue(s['total_amount']);
      prevProfit += _doubleValue(s['profit']);
    }

    double prevPengeluaran = 0;
    for (var e in prevExpenses) {
      prevPengeluaran += _doubleValue(e['amount']);
    }

    double prevKasMasuk = 0;
    double prevKasKeluar = 0;
    for (var k in prevKas) {
      final amt = _doubleValue(k['amount']);
      if (k['tipe'] == 'masuk') {
        prevKasMasuk += amt;
      } else {
        prevKasKeluar += amt;
      }
    }

    // Calculate Deltas
    double omzetDelta = _calculateDelta(omzet, prevOmzet);
    double profitDelta = _calculateDelta(profit, prevProfit);
    double pengeluaranDelta = _calculateDelta(pengeluaran, prevPengeluaran);
    double netCashflowDelta = _calculateDelta(kasMasuk - kasKeluar, prevKasMasuk - prevKasKeluar);

    // Grouping for Charts
    List<ChartDataPoint> trendData = _groupTrendData(currentSales, period);
    List<ChartDataPoint> cashflowData = _groupCashflowData(currentKas, period);

    // Top Products
    final productMap = <String, int>{};
    for (var item in currentItems) {
      final name = _stringValue(item['nama_produk'], fallback: 'Produk');
      final qty = _intValue(item['quantity']);
      productMap[name] = (productMap[name] ?? 0) + qty;
    }
    final sortedProducts = productMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProducts = sortedProducts
        .take(3)
        .map((e) => TopProduct(name: e.key, quantity: e.value))
        .toList();

    // Busiest Period
    final busiest = _findBusiestPeriod(currentSales, period);

    final totalPayment = tunai + hutang;
    
    return StatsSummary(
      omzet: omzet,
      profit: profit,
      pengeluaran: pengeluaran,
      netCashflow: kasMasuk - kasKeluar,
      kasMasuk: kasMasuk,
      kasKeluar: kasKeluar,
      jumlahTransaksi: currentSales.length,
      omzetDelta: omzetDelta,
      profitDelta: profitDelta,
      pengeluaranDelta: pengeluaranDelta,
      netCashflowDelta: netCashflowDelta,
      trendData: trendData,
      cashflowData: cashflowData,
      topProducts: topProducts,
      busiestPeriod: busiest,
      averageTransaction: currentSales.isEmpty ? 0 : omzet / currentSales.length,
      tunaiPercentage: totalPayment == 0 ? 0 : (tunai / totalPayment) * 100,
      hutangPercentage: totalPayment == 0 ? 0 : (hutang / totalPayment) * 100,
    );
  }

  double _calculateDelta(double current, double prev) {
    if (prev == 0) return current > 0 ? 100 : 0;
    return ((current - prev) / prev) * 100;
  }

  List<ChartDataPoint> _groupTrendData(
    List<Map<String, dynamic>> sales,
    StatsPeriod period,
  ) {
    final groups = <String, List<double>>{};

    for (var s in sales) {
      final date =
          DateTime.parse(_stringValue(s['tanggal'])).toLocal();
      final label = _getLabelForDate(date, period);
      groups.putIfAbsent(label, () => [0, 0]);
      groups[label]![0] += _doubleValue(s['total_amount']);
      groups[label]![1] += _doubleValue(s['profit']);
    }

    return _fillMissingLabels(groups, period);
  }

  List<ChartDataPoint> _groupCashflowData(
    List<Map<String, dynamic>> kas,
    StatsPeriod period,
  ) {
    final groups = <String, List<double>>{};

    for (var k in kas) {
      final date =
          DateTime.parse(_stringValue(k['tanggal'])).toLocal();
      final label = _getLabelForDate(date, period);
      groups.putIfAbsent(label, () => [0, 0]);
      final amt = _doubleValue(k['amount']);
      if (k['tipe'] == 'masuk') {
        groups[label]![0] += amt;
      } else {
        groups[label]![1] += amt;
      }
    }

    return _fillMissingLabels(groups, period);
  }

  String _getLabelForDate(DateTime date, StatsPeriod period) {
    switch (period) {
      case StatsPeriod.harian:
        return "${date.hour.toString().padLeft(2, '0')}:00";
      case StatsPeriod.mingguan:
        return DateFormat('EEE', 'id_ID').format(date);
      case StatsPeriod.bulanan:
        return date.day.toString();
      case StatsPeriod.triwulanan:
        return DateFormat('MMM', 'id_ID').format(date);
    }
  }

  List<ChartDataPoint> _fillMissingLabels(
    Map<String, List<double>> groups,
    StatsPeriod period,
  ) {
    final labels = <String>[];
    final now = DateTime.now();

    switch (period) {
      case StatsPeriod.harian:
        for (int i = 0; i < 24; i++) {
          labels.add("${i.toString().padLeft(2, '0')}:00");
        }
        break;
      case StatsPeriod.mingguan:
        final start = now.subtract(Duration(days: now.weekday - 1));
        for (int i = 0; i < 7; i++) {
          labels.add(DateFormat('EEE', 'id_ID').format(start.add(Duration(days: i))));
        }
        break;
      case StatsPeriod.bulanan:
        final days = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 1; i <= days; i++) {
          labels.add(i.toString());
        }
        break;
      case StatsPeriod.triwulanan:
        for (int i = 2; i >= 0; i--) {
          labels.add(DateFormat('MMM', 'id_ID').format(DateTime(now.year, now.month - i, 1)));
        }
        break;
    }

    return labels.map((l) {
      final vals = groups[l] ?? [0.0, 0.0];
      return ChartDataPoint(label: l, value1: vals[0], value2: vals[1]);
    }).toList();
  }

  String _findBusiestPeriod(List<Map<String, dynamic>> sales, StatsPeriod period) {
    if (sales.isEmpty) return '-';
    final counts = <String, int>{};
    for (var s in sales) {
      final date =
          DateTime.parse(_stringValue(s['tanggal'])).toLocal();
      final label = _getLabelForDate(date, period);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
