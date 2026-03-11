import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  const ReceiptPage({super.key, required this.transactionData});

  @override
  Widget build(BuildContext context) {
    final cache = DataCacheService.instance;
    final namaWarung = cache.warungName ?? 'NAMA WARUNG';
    final alamatWarung = ''; // Not cached yet in DataCacheService

    final num diskon = transactionData['diskon'] ?? 0;
    final num netTotal = transactionData['net_total'] ?? 0;
    final String paymentMethod = transactionData['payment_method'] ?? 'TUNAI';
    final String? customerName = transactionData['customer_name'] as String?;
    
    // Penjualan Master Data
    final penjualan = transactionData['penjualan'] as Map<String, dynamic>? ?? {};
    final invoiceNo = penjualan['invoice_no'] as String? ?? 'INV-XXXX';
    final totalAmount = penjualan['total_amount'] as num? ?? 0;
    final amountPaid = penjualan['amount_paid'] as num? ?? 0;
    final amountChange = penjualan['amount_change'] as num? ?? 0;
    
    // Parse date safely
    DateTime? tanggalTx;
    if (penjualan['tanggal'] != null) {
      tanggalTx = DateTime.tryParse(penjualan['tanggal'].toString());
    }
    tanggalTx ??= DateTime.now();
    final tanggalStr = DateFormat('dd MMM yyyy HH:mm').format(tanggalTx);

    final items = transactionData['items'] as List<dynamic>? ?? [];

    final currencyCcy = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF3A9B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Transaksi Berhasil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Jika user klik back arrow di Appbar, default ke POS awal
            context.go('/transaksi/pos');
          },
        ),
      ),
      body: Column(
        children: [
          // Success Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primary, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Pembayaran Sukses!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            namaWarung.toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                            textAlign: TextAlign.center,
                          ),
                          if (alamatWarung.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              alamatWarung,
                              style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(color: Colors.black54),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Tx Metadata
                    Text('No: $invoiceNo', style: const TextStyle(fontSize: 12, fontFamily: 'Courier')),
                    Text('Tgl: $tanggalStr', style: const TextStyle(fontSize: 12, fontFamily: 'Courier')),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 12),
                    
                    // Items List
                    ...items.map((item) {
                      final name = item['nama_produk'] as String? ?? '';
                      final qty = item['quantity'] as num? ?? 0;
                      final sub = item['subtotal'] as num? ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '$name (x$qty)',
                                style: const TextStyle(fontSize: 12, fontFamily: 'Courier'),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                currencyCcy.format(sub),
                                style: const TextStyle(fontSize: 12, fontFamily: 'Courier'),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 4),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 4),
                    
                    // Subtotal / Discount / Total
                    _buildReceiptRow('Subtotal:', currencyCcy.format(totalAmount)),
                    if (diskon > 0)
                      _buildReceiptRow('Diskon:', '-${currencyCcy.format(diskon)}'),
                    _buildReceiptRow('Total:', currencyCcy.format(netTotal), isBold: true),
                    
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 12),
                    
                    // Payment conditional view
                    if (paymentMethod.toUpperCase() == 'TUNAI') ...[
                      _buildReceiptRow('Tunai:', currencyCcy.format(amountPaid)),
                      _buildReceiptRow('Kembalian:', currencyCcy.format(amountChange)),
                    ] else ...[
                      _buildReceiptRow('Pelanggan:', customerName ?? '-'),
                      _buildReceiptRow('DP / Uang Muka:', currencyCcy.format(amountPaid)),
                      _buildReceiptRow('Sisa Hutang:', currencyCcy.format(netTotal - amountPaid)),
                    ],
                    
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Terima Kasih!',
                        style: TextStyle(fontSize: 14, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppToast.showWarning(context, 'Printer belum disiapkan.');
                  },
                  icon: const Icon(Icons.print, color: Color(0xFFF8BD00)),
                  label: const Text(
                    'CETAK STRUK',
                    style: TextStyle(color: Color(0xFFF8BD00), fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFF8BD00), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/transaksi/pos');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SELESAI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontFamily: 'Courier', fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontFamily: 'Courier', fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
