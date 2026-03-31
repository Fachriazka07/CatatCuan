import 'package:shared_preferences/shared_preferences.dart';

class PrinterDeviceInfo {
  const PrinterDeviceInfo({
    required this.name,
    required this.macAddress,
    this.isBle = false,
  });

  final String name;
  final String macAddress;
  final bool isBle;

  bool get isValid => name.trim().isNotEmpty && macAddress.trim().isNotEmpty;
}

class PrinterSettingsService {
  PrinterSettingsService._();

  static const String _keyPrinterName = 'printer_bluetooth_name';
  static const String _keyPrinterMac = 'printer_bluetooth_mac';
  static const String _keyPrinterIsBle = 'printer_bluetooth_is_ble';

  static Future<PrinterDeviceInfo?> getSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyPrinterName) ?? '';
    final macAddress = prefs.getString(_keyPrinterMac) ?? '';
    final isBle = prefs.getBool(_keyPrinterIsBle) ?? false;

    final printer = PrinterDeviceInfo(
      name: name,
      macAddress: macAddress,
      isBle: isBle,
    );
    return printer.isValid ? printer : null;
  }

  static Future<void> saveSelectedPrinter(PrinterDeviceInfo printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterName, printer.name.trim());
    await prefs.setString(_keyPrinterMac, printer.macAddress.trim());
    await prefs.setBool(_keyPrinterIsBle, printer.isBle);
  }

  static Future<void> clearSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrinterName);
    await prefs.remove(_keyPrinterMac);
    await prefs.remove(_keyPrinterIsBle);
  }
}
