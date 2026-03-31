import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:simple_barcode_scanner/screens/shared.dart';
import 'dart:async';

/// Helper to scan a barcode exactly once.
///
/// The default [SimpleBarcodeScanner.scanBarcode] can fire its `onScanned`
/// callback multiple times before [Navigator.pop] completes, causing a
/// double-pop / double-scan UX glitch. This helper guards against that.
class BarcodeHelper {
  static Completer<String?>? _activeScanCompleter;

  static Future<String?> scanOnce(
    BuildContext context, {
    String appBarTitle = 'Scan Barcode',
  }) async {
    final activeScan = _activeScanCompleter;
    if (activeScan != null && !activeScan.isCompleted) {
      return activeScan.future;
    }

    final completer = Completer<String?>();
    _activeScanCompleter = completer;
    bool hasPopped = false;
    try {
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
              // Guard: only pop once per scan session.
              if (!hasPopped && ctx.mounted) {
                hasPopped = true;
                Navigator.pop(ctx, res);
              }
            },
          ),
        ),
      );

      // Give the scanner route a brief moment to fully dispose before
      // allowing a new scan session. This prevents immediate reopen glitches.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (identical(_activeScanCompleter, completer)) {
        _activeScanCompleter = null;
      }
    }
  }
}
