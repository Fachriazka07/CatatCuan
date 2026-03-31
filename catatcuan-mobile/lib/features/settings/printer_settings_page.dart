import 'package:catatcuan_mobile/core/services/bluetooth_printer_service.dart';
import 'package:catatcuan_mobile/core/services/printer_settings_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isScanning = false;
  PrinterDeviceInfo? _selectedPrinter;
  List<PrinterDeviceInfo> _detectedPrinters = [];

  Future<void> _showManualPrinterDialog() async {
    final nameController = TextEditingController(
      text: _selectedPrinter?.name ?? 'Printer Kasir',
    );
    final macController = TextEditingController(
      text: _selectedPrinter?.macAddress ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Input Printer Manual',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gunakan opsi ini kalau printer struk tidak muncul di daftar. Isi nama bebas dan MAC address printer Bluetooth, misalnya 66:32:DB:AA:1F:09.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Printer',
                    hintText: 'Contoh: Printer Kasir',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: macController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'MAC Address',
                    hintText: 'Contoh: 66:32:DB:AA:1F:09',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final printer = PrinterDeviceInfo(
                  name: nameController.text.trim(),
                  macAddress: macController.text.trim().toUpperCase(),
                );

                if (!printer.isValid) {
                  AppToast.showWarning(
                    context,
                    'Nama printer dan MAC address wajib diisi.',
                  );
                  return;
                }

                await PrinterSettingsService.saveSelectedPrinter(printer);
                if (!mounted) return;

                setState(() {
                  _selectedPrinter = printer;
                });

                Navigator.pop(dialogContext);
                AppToast.showSuccess(
                  context,
                  'Printer manual berhasil disimpan.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);

    try {
      final selectedPrinter = await PrinterSettingsService.getSelectedPrinter();

      if (!mounted) return;
      setState(() {
        _selectedPrinter = selectedPrinter;
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isScanning = true;
      _detectedPrinters = [];
    });

    try {
      final printers = await BluetoothPrinterService.instance.scanNearbyPrinters();
      if (!mounted) return;

      setState(() {
        _detectedPrinters = printers;
      });

      if (printers.isEmpty) {
        AppToast.showInfo(
          context,
          'Scan selesai. Belum ada printer yang terdeteksi.',
        );
      } else {
        AppToast.showSuccess(
          context,
          '${printers.length} printer berhasil ditemukan.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _selectPrinter(PrinterDeviceInfo printer) async {
    await PrinterSettingsService.saveSelectedPrinter(printer);
    if (!mounted) return;

    setState(() {
      _selectedPrinter = printer;
    });

    AppToast.showSuccess(
      context,
      'Printer ${printer.name} berhasil dipilih.',
    );
  }

  Future<void> _clearSelectedPrinter() async {
    await PrinterSettingsService.clearSelectedPrinter();
    if (!mounted) return;

    setState(() {
      _selectedPrinter = null;
    });

    AppToast.showInfo(context, 'Printer default dihapus.');
  }

  Future<void> _testPrinter() async {
    setState(() => _isTesting = true);
    try {
      final selectedPrinter = await PrinterSettingsService.getSelectedPrinter();
      if (!mounted) return;
      if (selectedPrinter == null) {
        throw Exception('Pilih printer Bluetooth dulu.');
      }

      await BluetoothPrinterService.instance.printTestTicket();
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Test print berhasil dikirim ke printer.',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Printer Bluetooth',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _scanPrinters,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Cari printer struk Bluetooth yang menyala di sekitar kamu. Setelah ketemu, pilih satu printer default untuk tombol cetak struk.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              _buildSelectedPrinterCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildPairedPrintersCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPrinterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Printer Default',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedPrinter == null)
            Text(
              'Belum ada printer yang dipilih.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPrinter!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPrinter!.macAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPrinter!.isBle
                      ? 'Mode: BLE'
                      : 'Mode: Bluetooth Classic',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _scanPrinters,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isScanning ? 'Mencari...' : 'Cari Printer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testPrinter,
                icon: _isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print),
                label: Text(_isTesting ? 'Mengecek...' : 'Tes Printer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _showManualPrinterDialog,
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Input Manual kalau printer tidak muncul'),
          ),
        ),
      ],
    );
  }

  Widget _buildPairedPrintersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Printer Terdeteksi',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (_selectedPrinter != null)
                TextButton(
                  onPressed: _clearSelectedPrinter,
                  child: const Text('Hapus Default'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_isScanning)
            Text(
              'Sedang mencari printer Bluetooth di sekitar...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            )
          else if (_detectedPrinters.isEmpty)
            Text(
              'Belum ada printer yang muncul. Pastikan printer menyala, Bluetooth aktif, lalu tap Cari Printer.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            )
          else
            Column(
              children: _detectedPrinters.map((printer) {
                final isSelected =
                    _selectedPrinter?.macAddress == printer.macAddress;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.print_outlined,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printer.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              printer.macAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              printer.isBle ? 'BLE' : 'Bluetooth Classic',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 116,
                        child: ElevatedButton(
                          onPressed: () => _selectPrinter(printer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Colors.white : AppTheme.primary,
                            foregroundColor:
                                isSelected ? AppTheme.primary : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(isSelected ? 'Dipilih' : 'Pilih'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
