import 'dart:async';
import 'dart:io';

import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/printer_settings_service.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printer_service/thermal_printer.dart';

class BluetoothPrinterService {
  BluetoothPrinterService._();

  static final BluetoothPrinterService instance = BluetoothPrinterService._();

  final PrinterManager _printerManager = PrinterManager.instance;

  Future<bool> ensureReady() async {
    if (!Platform.isAndroid) {
      throw Exception('Printer Bluetooth saat ini hanya disiapkan untuk Android.');
    }

    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final isGranted = statuses.entries.every((entry) {
      final permission = entry.key;
      final status = entry.value;
      if (permission == Permission.locationWhenInUse && Platform.isAndroid) {
        return status.isGranted || status.isLimited;
      }
      return status.isGranted;
    });

    if (!isGranted) {
      throw Exception(
        'Izin Bluetooth dan lokasi belum aktif. Aktifkan Nearby devices dan Location untuk scan printer.',
      );
    }

    return true;
  }

  Future<List<PrinterDeviceInfo>> scanNearbyPrinters() async {
    await ensureReady();

    final merged = <String, PrinterDeviceInfo>{};

    for (final printer in await _scanWithMode(isBle: false)) {
      merged[printer.macAddress] = printer;
    }

    for (final printer in await _scanWithMode(isBle: true)) {
      merged.putIfAbsent(printer.macAddress, () => printer);
    }

    return merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<PrinterDeviceInfo>> _scanWithMode({
    required bool isBle,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final foundPrinters = <String, PrinterDeviceInfo>{};
    late final StreamSubscription<PrinterDevice> subscription;
    final completer = Completer<List<PrinterDeviceInfo>>();
    Timer? timer;

    subscription = _printerManager
        .discovery(type: PrinterType.bluetooth, isBle: isBle)
        .listen(
      (device) {
        final address = (device.address ?? '').trim().toUpperCase();
        if (address.isEmpty) {
          return;
        }

        final name = (device.name).trim().isEmpty
            ? 'Printer $address'
            : device.name.trim();
        final printer = PrinterDeviceInfo(
          name: name,
          macAddress: address,
          isBle: isBle,
        );
        foundPrinters[address] = printer;
      },
      onError: (Object error) {
        timer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Gagal scan printer Bluetooth: $error'),
          );
        }
      },
    );

    timer = Timer(timeout, () async {
      await subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(foundPrinters.values.toList());
      }
    });

    final printers = await completer.future;
    timer.cancel();
    await subscription.cancel();
    return printers;
  }

  Future<void> printTestTicket() async {
    await ensureReady();

    final selectedPrinter = await PrinterSettingsService.getSelectedPrinter();
    if (selectedPrinter == null) {
      throw Exception('Pilih printer Bluetooth dulu.');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        'TEST PRINTER',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('CatatCuan Bluetooth Printer'));
    bytes.addAll(
      generator.text(
        DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now()),
      ),
    );
    bytes.addAll(generator.feed(5));

    await _sendToSelectedPrinter(selectedPrinter: selectedPrinter, bytes: bytes);
  }

  Future<void> printReceipt({
    required Map<String, dynamic> transactionData,
    required DataCacheService cache,
  }) async {
    await ensureReady();

    final selectedPrinter = await PrinterSettingsService.getSelectedPrinter();
    if (selectedPrinter == null) {
      throw Exception('Pilih printer Bluetooth dulu di Pengaturan > Printer.');
    }

    final bytes = await _buildReceiptBytes(
      transactionData: transactionData,
      cache: cache,
    );

    await _sendToSelectedPrinter(selectedPrinter: selectedPrinter, bytes: bytes);
  }

  Future<void> _sendToSelectedPrinter({
    required PrinterDeviceInfo selectedPrinter,
    required List<int> bytes,
  }) async {
    final connected = await _printerManager.connect(
      type: PrinterType.bluetooth,
      model: BluetoothPrinterInput(
        address: selectedPrinter.macAddress,
        name: selectedPrinter.name,
        isBle: selectedPrinter.isBle,
      ),
    );

    if (!connected) {
      throw Exception(
        'Gagal terhubung ke printer ${selectedPrinter.name}. Pastikan printer menyala dan dekat dengan HP.',
      );
    }

    try {
      final result = await _printerManager.send(
        type: PrinterType.bluetooth,
        bytes: bytes,
      );
      if (!result) {
        throw Exception('Printer terdeteksi, tapi data struk gagal dikirim.');
      }
      await Future.delayed(const Duration(milliseconds: 1500));
    } finally {
      await _printerManager.disconnect(type: PrinterType.bluetooth);
    }
  }

  Future<List<int>> _buildReceiptBytes({
    required Map<String, dynamic> transactionData,
    required DataCacheService cache,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    num toNum(Object? value) {
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '') ?? 0;
    }

    String toStringValue(Object? value, {String fallback = ''}) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? fallback : text;
    }

    final warungName = (cache.warungName ?? 'NAMA WARUNG').toUpperCase();
    final penjualan = transactionData['penjualan'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final items = (transactionData['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final invoiceNo = toStringValue(penjualan['invoice_no'], fallback: 'INV');
    final tanggal = DateTime.tryParse(
          penjualan['tanggal']?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now();
    final diskon = toNum(transactionData['diskon']);
    final netTotal = toNum(transactionData['net_total']);
    final totalAmount = toNum(penjualan['total_amount']);
    final amountPaid = toNum(penjualan['amount_paid']);
    final amountChange = toNum(penjualan['amount_change']);
    final paymentMethod = toStringValue(
      transactionData['payment_method'],
      fallback: 'TUNAI',
    ).toUpperCase();
    final customerName = toStringValue(transactionData['customer_name']);

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        warungName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('No: $invoiceNo'));
    bytes.addAll(
      generator.text(
        'Tgl: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(tanggal)}',
      ),
    );
    bytes.addAll(generator.hr());

    for (final item in items) {
      final name = toStringValue(item['nama_produk'], fallback: 'Produk');
      final qty = toNum(item['quantity']);
      final subtotal = toNum(item['subtotal']);

      bytes.addAll(generator.text('$name (x$qty)'));
      bytes.addAll(
        generator.row([
          PosColumn(text: '', width: 6),
          PosColumn(
            text: currencyFormatter.format(subtotal),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Subtotal', width: 6),
        PosColumn(
          text: currencyFormatter.format(totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    if (diskon > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(text: 'Diskon', width: 6),
          PosColumn(
            text: '-${currencyFormatter.format(diskon)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'Total',
          width: 6,
          styles: PosStyles(bold: true),
        ),
        PosColumn(
          text: currencyFormatter.format(netTotal),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
          ),
        ),
      ]),
    );

    bytes.addAll(generator.hr());

    if (paymentMethod == 'TUNAI') {
      bytes.addAll(
        generator.row([
          PosColumn(text: 'Tunai', width: 6),
          PosColumn(
            text: currencyFormatter.format(amountPaid),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      bytes.addAll(
        generator.row([
          PosColumn(text: 'Kembalian', width: 6),
          PosColumn(
            text: currencyFormatter.format(amountChange),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    } else {
      bytes.addAll(
        generator.text(
          'Pelanggan: ${customerName.isEmpty ? '-' : customerName}',
        ),
      );
      bytes.addAll(
        generator.row([
          PosColumn(text: 'DP / Uang Muka', width: 6),
          PosColumn(
            text: currencyFormatter.format(amountPaid),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      bytes.addAll(
        generator.row([
          PosColumn(text: 'Sisa Hutang', width: 6),
          PosColumn(
            text: currencyFormatter.format(netTotal - amountPaid),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.feed(1));
    bytes.addAll(
      generator.text(
        'Terima Kasih!',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );
    bytes.addAll(generator.feed(6));

    return bytes;
  }
}
