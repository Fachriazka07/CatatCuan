import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:simple_barcode_scanner/screens/shared.dart';

/// Helper to scan a barcode exactly once.
///
/// The default [SimpleBarcodeScanner.scanBarcode] can fire its `onScanned`
/// callback multiple times before [Navigator.pop] completes, causing a
/// double-pop / double-scan UX glitch. This helper guards against that.
class BarcodeHelper {
  static Future<String?> scanOnce(
    BuildContext context, {
    String appBarTitle = 'Scan Barcode',
  }) async {
    bool hasPopped = false;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (ctx) => BarcodeScanner(
          lineColor: '#ff6666',
          cancelButtonText: 'Batal',
          isShowFlashIcon: true,
          scanType: ScanType.barcode,
          cameraFace: CameraFace.back,
          scanFormat: ScanFormat.ONLY_BARCODE,
          barcodeAppBar: BarcodeAppBar(
            appBarTitle: appBarTitle,
            centerTitle: false,
            enableBackButton: true,
            backButtonIcon: const Icon(Icons.arrow_back_ios),
          ),
          onScanned: (res) {
            // Guard: only pop once
            if (!hasPopped && ctx.mounted) {
              hasPopped = true;
              Navigator.pop(ctx, res);
            }
          },
        ),
      ),
    );
    return result;
  }
}
