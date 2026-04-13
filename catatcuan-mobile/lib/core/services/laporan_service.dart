import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportExportFile {
  const ReportExportFile({required this.file, required this.filename});

  final File file;
  final String filename;
}

class _ExportSection {
  const _ExportSection({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

class LaporanService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  final DateFormat _dateTimeFormatter = DateFormat(
    'dd MMM yyyy, HH.mm',
    'id_ID',
  );
  static final RegExp _stockExpensePattern = RegExp(
    r'belanja\s+stok',
    caseSensitive: false,
  );

  String _formatCashSourceLabel(String? source) {
    switch ((source ?? '').toLowerCase()) {
      case 'penjualan':
        return 'Penjualan';
      case 'pengeluaran':
        return 'Pengeluaran';
      case 'hutang_bayar':
        return 'Pembayaran Hutang';
      case 'saldo_awal':
        return 'Saldo Awal';
      case 'manual_masuk':
        return 'Uang Masuk';
      case 'manual_keluar':
        return 'Uang Keluar';
      case 'transfer':
        return 'Transfer Saldo';
      case 'adjustment':
        return 'Penyesuaian Saldo';
      default:
        final cleaned = (source ?? '').replaceAll('_', ' ').trim();
        if (cleaned.isEmpty) {
          return 'Transaksi';
        }
        return cleaned[0].toUpperCase() + cleaned.substring(1);
    }
  }

  Future<Map<String, dynamic>> getLaporanSummary({
    required String warungId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toUtc().toIso8601String();
    final endStr = endDate.toUtc().toIso8601String();

    try {
      final salesRes = await _supabase
          .from('PENJUALAN')
          .select('tanggal, total_amount, profit, payment_method')
          .eq('warung_id', warungId)
          .gte('tanggal', startStr)
          .lte('tanggal', endStr);

      double totalPenjualan = 0;
      double totalProfitPenjualan = 0;
      double penjualanTunai = 0;
      double penjualanHutang = 0;
      final salesItems = <Map<String, dynamic>>[];
      for (var sale in salesRes) {
        final totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0;
        final profit = (sale['profit'] as num?)?.toDouble() ?? 0;
        final paymentMethod = (sale['payment_method'] as String?) ?? '-';
        totalPenjualan += totalAmount;
        totalProfitPenjualan += profit;

        if (paymentMethod.toLowerCase() == 'hutang') {
          penjualanHutang += totalAmount;
        } else {
          penjualanTunai += totalAmount;
        }

        salesItems.add({
          'tanggal': sale['tanggal'],
          'payment_method': paymentMethod,
          'total_amount': totalAmount,
          'profit': profit,
        });
      }
      final jumlahTransaksi = salesRes.length;
      salesItems.sort(
        (a, b) => (DateTime.tryParse(b['tanggal']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
          DateTime.tryParse(a['tanggal']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

      final expenseRes = await _supabase
          .from('PENGELUARAN')
          .select('tanggal, amount, keterangan, KATEGORI_PENGELUARAN(nama_kategori)')
          .eq('warung_id', warungId)
          .gte('tanggal', startStr)
          .lte('tanggal', endStr);

      double totalPengeluaran = 0;
      double totalPengeluaranOperasional = 0;
      double pengeluaranTerbesar = 0;
      final kategoriPengeluaranMap = <String, double>{};
      final expenseItems = <Map<String, dynamic>>[];
      for (var exp in expenseRes) {
        final amount = (exp['amount'] as num?)?.toDouble() ?? 0;
        totalPengeluaran += amount;
        if (amount > pengeluaranTerbesar) {
          pengeluaranTerbesar = amount;
        }

        final kategoriMap = exp['KATEGORI_PENGELUARAN'] as Map<String, dynamic>?;
        final kategoriNama = (kategoriMap?['nama_kategori'] as String?)?.trim();
        final key = kategoriNama == null || kategoriNama.isEmpty
            ? 'Tanpa Kategori'
            : kategoriNama;
        final isStockExpense = _stockExpensePattern.hasMatch(key);
        if (!isStockExpense) {
          totalPengeluaranOperasional += amount;
        }
        kategoriPengeluaranMap[key] = (kategoriPengeluaranMap[key] ?? 0) + amount;
        expenseItems.add({
          'tanggal': exp['tanggal'],
          'kategori': key,
          'keterangan': (exp['keterangan'] as String?)?.trim() ?? '',
          'amount': amount,
        });
      }
      final jumlahPengeluaran = expenseRes.length;
      final rataRataPengeluaran = jumlahPengeluaran == 0
          ? 0.0
          : totalPengeluaran / jumlahPengeluaran;
      final kategoriPengeluaranList = kategoriPengeluaranMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      expenseItems.sort(
        (a, b) => (DateTime.tryParse(b['tanggal']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
          DateTime.tryParse(a['tanggal']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

      final labaBersih = totalProfitPenjualan - totalPengeluaranOperasional;

      final kasRes = await _supabase
          .from('BUKU_KAS')
          .select('tipe, amount, sumber, keterangan, tanggal')
          .eq('warung_id', warungId)
          .gte('tanggal', startStr)
          .lte('tanggal', endStr);

      double kasMasuk = 0;
      double kasKeluar = 0;
      final cashItems = <Map<String, dynamic>>[];
      for (var kas in kasRes) {
        final amount = (kas['amount'] as num?)?.toDouble() ?? 0;
        final tipe = (kas['tipe'] as String? ?? '').toLowerCase();

        if (tipe == 'masuk') {
          kasMasuk += amount;
        } else {
          kasKeluar += amount;
        }

        cashItems.add({
          'title': _formatCashSourceLabel(kas['sumber'] as String?),
          'subtitle': (kas['keterangan'] as String?)?.trim().isNotEmpty == true
              ? (kas['keterangan'] as String).trim()
              : 'Mutasi kas tercatat',
          'amount': amount,
          'type': tipe,
          'tanggal': kas['tanggal'],
        });
      }
      final arusKasBersih = kasMasuk - kasKeluar;
      final jumlahMutasiKas = kasRes.length;

      final itemsRes = await _supabase
          .from('PENJUALAN_ITEM')
          .select('nama_produk, quantity, PENJUALAN!inner(warung_id, tanggal)')
          .eq('PENJUALAN.warung_id', warungId)
          .gte('PENJUALAN.tanggal', startStr)
          .lte('PENJUALAN.tanggal', endStr);

      final topProdukMap = <String, int>{};
      for (var item in itemsRes) {
        final name = (item['nama_produk'] as String?) ?? 'Produk Tanpa Nama';
        final qty = (item['quantity'] as num).toInt();
        topProdukMap[name] = (topProdukMap[name] ?? 0) + qty;
      }
      final productRes = await _supabase
          .from('PRODUK')
          .select('nama_produk, is_active')
          .eq('warung_id', warungId)
          .or('is_active.is.null,is_active.eq.true');

      final allProductNames = <String>{};
      for (final product in productRes) {
        final name = (product['nama_produk'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          allProductNames.add(name);
        }
      }
      allProductNames.addAll(topProdukMap.keys);

      final topProduk = allProductNames
          .map((name) => {'nama': name, 'qty': topProdukMap[name] ?? 0})
          .toList()
        ..sort((a, b) {
          final qtyA = (a['qty'] as int?) ?? 0;
          final qtyB = (b['qty'] as int?) ?? 0;
          if (qtyA != qtyB) {
            return qtyB.compareTo(qtyA);
          }
          final nameA = (a['nama'] as String?) ?? '';
          final nameB = (b['nama'] as String?) ?? '';
          return nameA.compareTo(nameB);
        });

      final hutangRes = await _supabase
          .from('HUTANG')
          .select(
            'id, amount_awal, amount_terbayar, amount_sisa, jenis, status, tanggal_jatuh_tempo, PELANGGAN(nama)',
          )
          .eq('warung_id', warungId)
          .gte('created_at', startStr)
          .lte('created_at', endStr);

      double totalHutang = 0;
      double totalPiutang = 0;
      double hutangTerbayar = 0;
      double piutangTerbayar = 0;
      double totalHutangSisa = 0;
      double totalPiutangSisa = 0;
      int jumlahTagihanAktif = 0;
      int jumlahJatuhTempo = 0;
      final debtItems = <Map<String, dynamic>>[];

      for (var h in hutangRes) {
        final jenis = (h['jenis'] as String? ?? '').toUpperCase();
        final awal = (h['amount_awal'] as num?)?.toDouble() ?? 0;
        final terbayar = (h['amount_terbayar'] as num?)?.toDouble() ?? 0;
        final sisa = (h['amount_sisa'] as num?)?.toDouble() ?? 0;
        final status = (h['status'] as String? ?? '').replaceAll('_', ' ').trim();
        final pelangganMap = h['PELANGGAN'] as Map<String, dynamic>?;
        final namaPelanggan =
            (pelangganMap?['nama'] as String?)?.trim().isNotEmpty == true
                ? (pelangganMap!['nama'] as String).trim()
                : 'Pelanggan';

        if (jenis == 'PIUTANG') {
          totalPiutang += awal;
          piutangTerbayar += terbayar;
          totalPiutangSisa += sisa;
        } else {
          totalHutang += awal;
          hutangTerbayar += terbayar;
          totalHutangSisa += sisa;
        }

        if (sisa > 0) {
          jumlahTagihanAktif += 1;
        }

        final jatuhTempoRaw = h['tanggal_jatuh_tempo'];
        if (jatuhTempoRaw != null && sisa > 0) {
          final dueDate = DateTime.tryParse(jatuhTempoRaw.toString());
          if (dueDate != null && dueDate.isBefore(DateTime.now())) {
            jumlahJatuhTempo += 1;
          }
        }

        debtItems.add({
          'nama': namaPelanggan,
          'jenis': jenis == 'PIUTANG' ? 'Piutang' : 'Hutang',
          'status': status.isEmpty ? 'Belum lunas' : status,
          'amount': sisa,
        });
      }
      debtItems.sort(
        (a, b) => ((b['amount'] as num?)?.toDouble() ?? 0).compareTo(
          (a['amount'] as num?)?.toDouble() ?? 0,
        ),
      );

      return {
        'laba_bersih': labaBersih,
        'penjualan': totalPenjualan,
        'profit_penjualan': totalProfitPenjualan,
        'penjualan_tunai': penjualanTunai,
        'penjualan_hutang': penjualanHutang,
        'jumlah_transaksi': jumlahTransaksi,
        'sales_items': salesItems,
        'pengeluaran': totalPengeluaran,
        'pengeluaran_operasional': totalPengeluaranOperasional,
        'jumlah_pengeluaran': jumlahPengeluaran,
        'rata_rata_pengeluaran': rataRataPengeluaran,
        'pengeluaran_terbesar': pengeluaranTerbesar,
        'expense_items': expenseItems,
        'kas_masuk': kasMasuk,
        'kas_keluar': kasKeluar,
        'arus_kas_bersih': arusKasBersih,
        'jumlah_mutasi_kas': jumlahMutasiKas,
        'top_produk': topProduk,
        'kategori_pengeluaran': kategoriPengeluaranList
            .take(5)
            .map((e) => {'nama': e.key, 'amount': e.value})
            .toList(),
        'cash_items': cashItems.take(5).toList(),
        'total_hutang': totalHutang,
        'total_piutang': totalPiutang,
        'hutang_terbayar': hutangTerbayar,
        'piutang_terbayar': piutangTerbayar,
        'total_hutang_sisa': totalHutangSisa,
        'total_piutang_sisa': totalPiutangSisa,
        'total_tagihan_sisa': totalHutangSisa + totalPiutangSisa,
        'jumlah_tagihan_aktif': jumlahTagihanAktif,
        'jumlah_jatuh_tempo': jumlahJatuhTempo,
        'debt_items': debtItems.take(5).toList(),
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<ReportExportFile> exportReportAsExcel({
    required String reportTypeKey,
    required String reportTitle,
    required String warungName,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> reportData,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Ringkasan') {
      excel.delete(defaultSheet);
    }
    final summarySheet = excel['Ringkasan'];
    final metrics = _buildMetricRows(reportTypeKey, reportData);
    final sections = _buildSections(reportTypeKey, reportData);

    _buildSummarySheet(
      sheet: summarySheet,
      reportTitle: reportTitle,
      warungName: warungName,
      startDate: startDate,
      endDate: endDate,
      metrics: metrics,
      sections: sections,
    );

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final sheetName = _buildSheetName(i, section.title);
      final detailSheet = excel[sheetName];
      _buildDetailSheet(detailSheet, section);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Gagal membuat file Excel.');
    }

    final filename = _buildFilename(reportTypeKey, startDate, 'xlsx');
    return _writeExportFile(Uint8List.fromList(encoded), filename);
  }

  void _buildSummarySheet({
    required Sheet sheet,
    required String reportTitle,
    required String warungName,
    required DateTime startDate,
    required DateTime endDate,
    required List<List<String>> metrics,
    required List<_ExportSection> sections,
  }) {
    final tableBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.black,
    );
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('FF16A34A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );
    final labelStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FF166534'),
      backgroundColorHex: ExcelColor.fromHexString('FFE8F5E9'),
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString('FFFBBF24'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );
    final bodyStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('FF1F2937'),
      backgroundColorHex: ExcelColor.white,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );
    _writeCell(sheet, 0, 0, reportTitle, style: titleStyle);

    _writeCell(sheet, 1, 0, 'Warung', style: labelStyle);
    _writeCell(sheet, 1, 1, warungName, style: bodyStyle);
    _writeCell(sheet, 2, 0, 'Periode', style: labelStyle);
    _writeCell(sheet, 2, 1, _formatPeriod(startDate, endDate), style: bodyStyle);
    _writeCell(sheet, 3, 0, 'Diekspor', style: labelStyle);
    _writeCell(
      sheet,
      3,
      1,
      _dateTimeFormatter.format(DateTime.now()),
      style: bodyStyle,
    );

    _writeCell(sheet, 5, 0, 'Ringkasan Metrik', style: headerStyle);
    _writeCell(sheet, 5, 1, 'Nilai', style: headerStyle);
    for (var i = 0; i < metrics.length; i++) {
      _writeCell(sheet, 6 + i, 0, metrics[i][0], style: bodyStyle);
      _writeCell(sheet, 6 + i, 1, metrics[i][1], style: bodyStyle);
    }

    var sectionRow = 6 + metrics.length + 2;
    _writeCell(sheet, sectionRow, 0, 'Isi Sheet Detail', style: headerStyle);
    _writeCell(sheet, sectionRow, 1, 'Jumlah Data', style: headerStyle);
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final countLabel =
          section.rows.isEmpty ? 'Tidak ada data' : '${section.rows.length} baris';
      _writeCell(sheet, sectionRow + i + 1, 0, section.title, style: bodyStyle);
      _writeCell(sheet, sectionRow + i + 1, 1, countLabel, style: bodyStyle);
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
  }

  void _buildDetailSheet(Sheet sheet, _ExportSection section) {
    final tableBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.black,
    );
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('FF16A34A'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString('FFFBBF24'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );
    final bodyStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('FF1F2937'),
      backgroundColorHex: ExcelColor.white,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );
    final emptyStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('FF6B7280'),
      backgroundColorHex: ExcelColor.fromHexString('FFF9FAFB'),
      italic: true,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final maxColumn = section.headers.isEmpty ? 0 : section.headers.length - 1;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: maxColumn, rowIndex: 0),
    );
    _writeCell(sheet, 0, 0, section.title, style: titleStyle);

    for (var i = 0; i < section.headers.length; i++) {
      _writeCell(sheet, 2, i, section.headers[i], style: headerStyle);
      final lowerHeader = section.headers[i].toLowerCase();
      final width = switch (lowerHeader) {
        'no' => 8.0,
        'tanggal' => 16.0,
        'qty' || 'jml' => 10.0,
        'nominal' || 'total' || 'profit' => 18.0,
        'catatan' || 'keterangan' => 28.0,
        _ => 20.0,
      };
      sheet.setColumnWidth(i, width);
    }

    if (section.rows.isEmpty) {
      _writeCell(sheet, 3, 0, 'Tidak ada data pada periode ini.', style: emptyStyle);
      return;
    }

    for (var rowIndex = 0; rowIndex < section.rows.length; rowIndex++) {
      final row = section.rows[rowIndex];
      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        _writeCell(sheet, rowIndex + 3, colIndex, row[colIndex], style: bodyStyle);
      }
    }
  }

  Future<ReportExportFile> exportReportAsPdf({
    required String reportTypeKey,
    required String reportTitle,
    required String warungName,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();
    final metrics = _buildMetricRows(reportTypeKey, reportData);
    final sections = _buildSections(reportTypeKey, reportData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            reportTitle,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Warung: $warungName'),
          pw.Text('Periode: ${_formatPeriod(startDate, endDate)}'),
          pw.Text('Diekspor: ${_dateTimeFormatter.format(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: const ['Metrik', 'Nilai'],
            data: metrics,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
            },
          ),
          for (final section in sections) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              section.title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: section.headers,
              data: section.rows.isEmpty
                  ? [
                      List<String>.generate(
                        section.headers.length,
                        (index) => index == 0 ? 'Tidak ada data' : '-',
                      ),
                    ]
                  : section.rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ],
      ),
    );

    final filename = _buildFilename(reportTypeKey, startDate, 'pdf');
    return _writeExportFile(await pdf.save(), filename);
  }

  List<List<String>> _buildMetricRows(
    String reportTypeKey,
    Map<String, dynamic> reportData,
  ) {
    switch (reportTypeKey) {
      case 'sales':
        return [
          ['Total Penjualan', _formatCurrency(_doubleValue(reportData, 'penjualan'))],
          ['Penjualan Tunai', _formatCurrency(_doubleValue(reportData, 'penjualan_tunai'))],
          ['Penjualan Hutang', _formatCurrency(_doubleValue(reportData, 'penjualan_hutang'))],
          ['Jumlah Transaksi', _intValue(reportData, 'jumlah_transaksi').toString()],
        ];
      case 'expense':
        return [
          ['Total Pengeluaran', _formatCurrency(_doubleValue(reportData, 'pengeluaran'))],
          ['Jumlah Catatan', _intValue(reportData, 'jumlah_pengeluaran').toString()],
          ['Rata-rata Pengeluaran', _formatCurrency(_doubleValue(reportData, 'rata_rata_pengeluaran'))],
          ['Pengeluaran Terbesar', _formatCurrency(_doubleValue(reportData, 'pengeluaran_terbesar'))],
        ];
      case 'cashBook':
        return [
          ['Kas Masuk', _formatCurrency(_doubleValue(reportData, 'kas_masuk'))],
          ['Kas Keluar', _formatCurrency(_doubleValue(reportData, 'kas_keluar'))],
          ['Arus Kas Bersih', _formatCurrency(_doubleValue(reportData, 'arus_kas_bersih'))],
          ['Jumlah Mutasi', _intValue(reportData, 'jumlah_mutasi_kas').toString()],
        ];
      case 'debt':
        return [
          ['Total Piutang', _formatCurrency(_doubleValue(reportData, 'total_piutang'))],
          ['Total Hutang', _formatCurrency(_doubleValue(reportData, 'total_hutang'))],
          ['Sisa Tagihan', _formatCurrency(_doubleValue(reportData, 'total_tagihan_sisa'))],
          ['Tagihan Aktif', _intValue(reportData, 'jumlah_tagihan_aktif').toString()],
          ['Jatuh Tempo', _intValue(reportData, 'jumlah_jatuh_tempo').toString()],
        ];
      case 'finance':
      default:
        return [
          ['Laba Bersih', _formatCurrency(_doubleValue(reportData, 'laba_bersih'))],
          ['Penjualan', _formatCurrency(_doubleValue(reportData, 'penjualan'))],
          ['Profit Penjualan', _formatCurrency(_doubleValue(reportData, 'profit_penjualan'))],
          ['Pengeluaran', _formatCurrency(_doubleValue(reportData, 'pengeluaran'))],
        ];
    }
  }

  List<_ExportSection> _buildSections(
    String reportTypeKey,
    Map<String, dynamic> reportData,
  ) {
    switch (reportTypeKey) {
      case 'sales':
        return [
          _ExportSection(
            title: 'Data Penjualan',
            headers: const ['No', 'Tanggal', 'Metode', 'Total', 'Profit'],
            rows: _listValue(reportData, 'sales_items')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    _formatDateValue(entry.value['tanggal']),
                    _formatPaymentMethod(entry.value['payment_method'] as String?),
                    _formatCurrency(
                      (entry.value['total_amount'] as num?)?.toDouble() ?? 0,
                    ),
                    _formatCurrency(
                      (entry.value['profit'] as num?)?.toDouble() ?? 0,
                    ),
                  ],
                )
                .toList(),
          ),
          _ExportSection(
            title: 'Produk Terlaris',
            headers: const ['No', 'Produk', 'Qty'],
            rows: _listValue(reportData, 'top_produk')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    (entry.value['nama'] as String?) ?? 'Produk',
                    _intFromDynamic(entry.value['qty']).toString(),
                  ],
                )
                .toList(),
          ),
        ];
      case 'expense':
        return [
          _ExportSection(
            title: 'Data Pengeluaran',
            headers: const ['No', 'Tanggal', 'Kategori', 'Catatan', 'Nominal'],
            rows: _listValue(reportData, 'expense_items')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    _formatDateValue(entry.value['tanggal']),
                    (entry.value['kategori'] as String?) ?? 'Tanpa Kategori',
                    ((entry.value['keterangan'] as String?)?.isNotEmpty ?? false)
                        ? entry.value['keterangan'] as String
                        : '-',
                    _formatCurrency(
                      (entry.value['amount'] as num?)?.toDouble() ?? 0,
                    ),
                  ],
                )
                .toList(),
          ),
          _ExportSection(
            title: 'Kategori Pengeluaran',
            headers: const ['No', 'Kategori', 'Nominal'],
            rows: _listValue(reportData, 'kategori_pengeluaran')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    (entry.value['nama'] as String?) ?? 'Kategori',
                    _formatCurrency(
                      (entry.value['amount'] as num?)?.toDouble() ?? 0,
                    ),
                  ],
                )
                .toList(),
          ),
        ];
      case 'cashBook':
        return [
          _ExportSection(
            title: 'Mutasi Kas',
            headers: const ['No', 'Tanggal', 'Tipe', 'Sumber', 'Keterangan', 'Nominal'],
            rows: _listValue(reportData, 'cash_items')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    _formatDateValue(entry.value['tanggal']),
                    _formatTipe(entry.value['type'] as String?),
                    (entry.value['title'] as String?) ?? 'Transaksi',
                    (entry.value['subtitle'] as String?) ?? '-',
                    _formatCurrency(
                      (entry.value['amount'] as num?)?.toDouble() ?? 0,
                    ),
                  ],
                )
                .toList(),
          ),
        ];
      case 'debt':
        return [
          _ExportSection(
            title: 'Hutang & Piutang',
            headers: const ['No', 'Nama', 'Jenis', 'Status', 'Nominal'],
            rows: _listValue(reportData, 'debt_items')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    (entry.value['nama'] as String?) ?? 'Pelanggan',
                    (entry.value['jenis'] as String?) ?? '-',
                    (entry.value['status'] as String?) ?? '-',
                    _formatCurrency(
                      (entry.value['amount'] as num?)?.toDouble() ?? 0,
                    ),
                  ],
                )
                .toList(),
          ),
        ];
      case 'finance':
      default:
        return [
          _ExportSection(
            title: 'Produk Terlaris',
            headers: const ['No', 'Produk', 'Qty'],
            rows: _listValue(reportData, 'top_produk')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    (entry.value['nama'] as String?) ?? 'Produk',
                    _intFromDynamic(entry.value['qty']).toString(),
                  ],
                )
                .toList(),
          ),
          _ExportSection(
            title: 'Kategori Pengeluaran',
            headers: const ['No', 'Kategori', 'Nominal'],
            rows: _listValue(reportData, 'kategori_pengeluaran')
                .asMap()
                .entries
                .map(
                  (entry) => [
                    '${entry.key + 1}',
                    (entry.value['nama'] as String?) ?? 'Kategori',
                    _formatCurrency(
                      (entry.value['amount'] as num?)?.toDouble() ?? 0,
                    ),
                  ],
                )
                .toList(),
          ),
        ];
    }
  }

  Future<ReportExportFile> _writeExportFile(
    Uint8List bytes,
    String filename,
  ) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return ReportExportFile(file: file, filename: filename);
  }

  List<Map<String, dynamic>> _listValue(
    Map<String, dynamic> data,
    String key,
  ) {
    return List<Map<String, dynamic>>.from(data[key] as List? ?? const []);
  }

  double _doubleValue(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toDouble() ?? 0;
  }

  int _intValue(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toInt() ?? 0;
  }

  int _intFromDynamic(dynamic value) {
    return (value as num?)?.toInt() ?? 0;
  }

  String _formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  String _formatPeriod(DateTime startDate, DateTime endDate) {
    return '${_dateFormatter.format(startDate)} - ${_dateFormatter.format(endDate)}';
  }

  String _formatDateTimeValue(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return '-';
    }
    return _dateTimeFormatter.format(parsed.toLocal());
  }

  String _formatDateValue(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return '-';
    }
    return _dateFormatter.format(parsed.toLocal());
  }

  String _formatTipe(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return '-';
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _formatPaymentMethod(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'tunai':
        return 'Tunai';
      case 'hutang':
        return 'Kasbon';
      default:
        return normalized.isEmpty
            ? '-'
            : normalized[0].toUpperCase() + normalized.substring(1);
    }
  }

  String _buildFilename(
    String reportTypeKey,
    DateTime startDate,
    String extension,
  ) {
    final safeType = _sanitizeFilename(reportTypeKey);
    final safeDate = DateFormat('yyyyMMdd_HHmm').format(startDate);
    return 'laporan_${safeType}_$safeDate.$extension';
  }

  String _sanitizeFilename(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _buildSheetName(int index, String title) {
    final sanitized = title
        .replaceAll(RegExp(r'[:\\\\/?*\\[\\]]'), '')
        .trim()
        .replaceAll(RegExp(r'\\s+'), ' ');
    final prefix = '${index + 1}_';
    final maxTitleLength = 31 - prefix.length;
    final safeLength = sanitized.length > maxTitleLength
        ? maxTitleLength
        : sanitized.length;
    final trimmed = sanitized.isEmpty
        ? 'Detail'
        : sanitized.substring(0, safeLength);
    return '$prefix$trimmed';
  }

  void _writeCell(
    Sheet sheet,
    int row,
    int column,
    String value, {
    CellStyle? style,
  }) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      TextCellValue(value),
      cellStyle: style,
    );
  }
}
