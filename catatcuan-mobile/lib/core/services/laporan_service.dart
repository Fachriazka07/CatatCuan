import 'package:supabase_flutter/supabase_flutter.dart';

class LaporanService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      // 1. Penjualan & Profit
      final salesRes = await _supabase
          .from('PENJUALAN')
          .select('total_amount, profit, payment_method')
          .eq('warung_id', warungId)
          .gte('tanggal', startStr)
          .lte('tanggal', endStr);

      double totalPenjualan = 0;
      double totalProfitPenjualan = 0;
      double penjualanTunai = 0;
      double penjualanHutang = 0;
      for (var sale in salesRes) {
        final totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0;
        totalPenjualan += totalAmount;
        totalProfitPenjualan += (sale['profit'] as num?)?.toDouble() ?? 0;

        if ((sale['payment_method'] as String? ?? '').toLowerCase() == 'hutang') {
          penjualanHutang += totalAmount;
        } else {
          penjualanTunai += totalAmount;
        }
      }
      final jumlahTransaksi = salesRes.length;

      // 2. Pengeluaran
      final expenseRes = await _supabase
          .from('PENGELUARAN')
          .select('amount, KATEGORI_PENGELUARAN(nama_kategori)')
          .eq('warung_id', warungId)
          .gte('tanggal', startStr)
          .lte('tanggal', endStr);

      double totalPengeluaran = 0;
      double pengeluaranTerbesar = 0;
      final kategoriPengeluaranMap = <String, double>{};
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
        kategoriPengeluaranMap[key] = (kategoriPengeluaranMap[key] ?? 0) + amount;
      }
      final jumlahPengeluaran = expenseRes.length;
      final rataRataPengeluaran = jumlahPengeluaran == 0
          ? 0.0
          : totalPengeluaran / jumlahPengeluaran;
      final kategoriPengeluaranList = kategoriPengeluaranMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 3. Laba Bersih
      final labaBersih = totalProfitPenjualan - totalPengeluaran;

      // 4. Buku Kas
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

      // 5. Produk Terlaris
      final itemsRes = await _supabase
          .from('PENJUALAN_ITEM')
          .select('nama_produk, quantity, PENJUALAN!inner(warung_id, tanggal)')
          .eq('PENJUALAN.warung_id', warungId)
          .gte('PENJUALAN.tanggal', startStr)
          .lte('PENJUALAN.tanggal', endStr);

      Map<String, int> topProdukMap = {};
      for (var item in itemsRes) {
        String name = (item['nama_produk'] as String?) ?? 'Produk Tanpa Nama';
        int qty = (item['quantity'] as num).toInt();
        topProdukMap[name] = (topProdukMap[name] ?? 0) + qty;
      }
      var topProdukList = topProdukMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      var topProduk = topProdukList
          .take(5)
          .map((e) => {'nama': e.key, 'qty': e.value})
          .toList();

      // 6. Hutang & Piutang Summary
      final hutangRes = await _supabase
          .from('HUTANG')
          .select(
            'id, amount_awal, amount_terbayar, amount_sisa, jenis, status, tanggal_jatuh_tempo, PELANGGAN(nama)',
          )
          .eq('warung_id', warungId)
          .gte('created_at', startStr)
          .lte('created_at', endStr);

      double totalHutang = 0; // We owe others
      double totalPiutang = 0; // Others owe us
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
        'pengeluaran': totalPengeluaran,
        'jumlah_pengeluaran': jumlahPengeluaran,
        'rata_rata_pengeluaran': rataRataPengeluaran,
        'pengeluaran_terbesar': pengeluaranTerbesar,
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
}
