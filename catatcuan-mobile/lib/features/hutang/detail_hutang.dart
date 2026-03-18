import 'package:catatcuan_mobile/core/services/hutang_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DetailHutangPage extends StatefulWidget {
  const DetailHutangPage({super.key, required this.initialData});
  final Map<String, dynamic> initialData;

  @override
  State<DetailHutangPage> createState() => _DetailHutangPageState();
}

class _DetailHutangPageState extends State<DetailHutangPage> {
  final _hutangService = HutangService();
  late Map<String, dynamic> _data;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  Map<String, dynamic>? get _pelangganData =>
      _data['PELANGGAN'] as Map<String, dynamic>?;

  String get _pelangganName =>
      _data['nama_kontak'] as String? ??
      (_pelangganData?['nama'] as String? ?? 'Tanpa Nama');

  DateTime _parseSafeDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return DateTime.now();
    }

    final sanitized = raw
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('"', '')
        .trim();

    return DateTime.tryParse(sanitized)?.toLocal() ?? DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initialData);
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _hutangService.getPayments(_data['id'] as String);
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data?'),
        content: const Text('Seluruh riwayat pembayaran juga akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _hutangService.deleteHutang(_data['id'] as String);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
        }
      }
    }
  }

  void _showPaymentSheet() {
    final controller = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bayar Hutang / Piutang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nominal Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      hintText: '0',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8BD00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final pageMessenger = ScaffoldMessenger.of(
                                this.context,
                              );
                              final modalNavigator = Navigator.of(ctx);
                              final val = double.tryParse(
                                controller.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                              );
                              if (val == null || val <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nominal tidak valid'),
                                  ),
                                );
                                return;
                              }
                              if (val > (_data['amount_sisa'] as num)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nominal pembayaran melebihi sisa tagihan!',
                                    ),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                await _hutangService.payHutang(
                                  _data['id'] as String,
                                  {
                                    'hutang_id': _data['id'] as String,
                                    'amount': val,
                                    'metode_bayar': 'tunai',
                                    'tanggal': DateTime.now().toIso8601String(),
                                  },
                                );

                                // Refresh Local Data
                                final currentTerbayar =
                                    (_data['amount_terbayar'] as num)
                                        .toDouble();
                                final amountAwal = (_data['amount_awal'] as num)
                                    .toDouble();
                                final newTerbayar = currentTerbayar + val;
                                final newSisa = amountAwal - newTerbayar;

                                setState(() {
                                  _data['amount_terbayar'] = newTerbayar;
                                  _data['amount_sisa'] = newSisa;
                                  _data['status'] = newSisa <= 0
                                      ? 'lunas'
                                      : 'belum_lunas';
                                });

                                if (!mounted || !ctx.mounted) {
                                  return;
                                }
                                modalNavigator.pop();
                                _fetchDetail();
                                pageMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Pembayaran berhasil!'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) {
                                  return;
                                }
                                pageMessenger.showSnackBar(
                                  SnackBar(content: Text('Gagal: $e')),
                                );
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SIMPAN PEMBAYARAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSheet() {
    final nameCtrl = TextEditingController(
      text: _data['nama_kontak'] as String? ?? (_pelangganData?['nama'] as String? ?? ''),
    );
    final notesCtrl = TextEditingController(
      text: _data['catatan'] as String? ?? '',
    );
    final amountCtrl = TextEditingController(
      text: (_data['amount_awal'] as num).toInt().toString(),
    );

    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Hutang / Piutang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nama Kontak',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Catatan (Opsional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      hintText: 'INPUT CATATAN',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Total Keseluruhan (Rp)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD1EDD8),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8BD00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final pageMessenger = ScaffoldMessenger.of(
                                this.context,
                              );
                              final modalNavigator = Navigator.of(ctx);
                              final newAmount = double.tryParse(
                                amountCtrl.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                              );
                              if (newAmount == null || newAmount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nominal tidak valid'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final currentTerbayar =
                                    (_data['amount_terbayar'] as num)
                                        .toDouble();
                                final newSisa = newAmount - currentTerbayar;

                                await _hutangService
                                    .updateHutang(_data['id'] as String, {
                                      'nama_kontak': nameCtrl.text.trim(),
                                      'catatan': notesCtrl.text.trim(),
                                      'amount_awal': newAmount,
                                      'amount_sisa': newSisa > 0 ? newSisa : 0,
                                      'status': newSisa <= 0
                                          ? 'lunas'
                                          : 'belum_lunas',
                                    });

                                setState(() {
                                  _data['nama_kontak'] = nameCtrl.text.trim();
                                  _data['catatan'] = notesCtrl.text.trim();
                                  _data['amount_awal'] = newAmount;
                                  _data['amount_sisa'] = newSisa > 0
                                      ? newSisa
                                      : 0;
                                  _data['status'] = newSisa <= 0
                                      ? 'lunas'
                                      : 'belum_lunas';
                                });

                                if (!mounted || !ctx.mounted) {
                                  return;
                                }
                                modalNavigator.pop();
                                pageMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Data diperbarui!'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) {
                                  return;
                                }
                                pageMessenger.showSnackBar(
                                  SnackBar(content: Text('Gagal: $e')),
                                );
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SIMPAN PERUBAHAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final name = _pelangganName;
    final notes = _data['catatan'] as String? ?? '-';
    final total = (_data['amount_awal'] as num).toDouble();
    final paid = (_data['amount_terbayar'] as num).toDouble();
    final debt = (_data['amount_sisa'] as num).toDouble();
    final isLunas = _data['status'] == 'lunas';
    final isHutang = _data['jenis'] == 'HUTANG'; // we owe them

    final double progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                _buildHeader(isHutang, isLunas),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD1EDD8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  name.isNotEmpty
                                      ? name.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isLunas
                                      ? const Color(0xFFD1EDD8)
                                      : const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  isLunas ? 'LUNAS' : 'BELUM LUNAS',
                                  style: TextStyle(
                                    color: isLunas
                                        ? AppTheme.primary
                                        : AppTheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildAmountRow(
                                'Catatan',
                                notes,
                                const Color(0xFF374151),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                ),
                              ),
                              _buildAmountRow(
                                'Total Keseluruhan',
                                currencyFormatter.format(total),
                                const Color(0xFF374151),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                ),
                              ),
                              _buildAmountRow(
                                'Sudah Dibayar',
                                currencyFormatter.format(paid),
                                AppTheme.primary,
                              ),
                              const SizedBox(height: 12),
                              _buildAmountRow(
                                'Sisa Tagihan',
                                currencyFormatter.format(debt),
                                AppTheme.error,
                              ),
                              const SizedBox(height: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.payment, size: 20),
                                label: const Text(
                                  'BAYAR',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                onPressed: isLunas ? null : _showPaymentSheet,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: const BorderSide(
                                    color: AppTheme.error,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                label: const Text(
                                  'HAPUS',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                onPressed: _deleteData,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                        const Text(
                          'Riwayat Pembayaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_payments.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada transaksi pembayaran.',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._payments.map(
                            (p) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF3F4F6),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFD1EDD8),
                                  child: Icon(
                                    Icons.check,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                title: const Text(
                                  'Pembayaran Tunai',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('dd MMM yyyy, HH:mm').format(
                                      _parseSafeDate(
                                        p['tanggal'] ?? p['created_at'],
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                trailing: Text(
                                  "+ ${currencyFormatter.format(p['amount'])}",
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                  ),
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
    );
  }

  Widget _buildHeader(bool isHutang, bool isLunas) {
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
          Text(
            isHutang ? 'Detail Hutang' : 'Detail Piutang',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: isLunas ? null : _showEditSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8BD00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
