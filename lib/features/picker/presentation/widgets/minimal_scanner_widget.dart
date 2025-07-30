import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:developer';

class MinimalScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const MinimalScannerWidget({super.key, required this.onBarcodeScanned});

  @override
  State<MinimalScannerWidget> createState() => _MinimalScannerWidgetState();
}

class _MinimalScannerWidgetState extends State<MinimalScannerWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Barcode'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              log("📱 Minimal scanner detected: ${barcode.rawValue}");
              widget.onBarcodeScanned(barcode.rawValue!);
              break;
            }
          }
        },
        errorBuilder: (context, error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Camera Error: ${error.errorCode}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  error.errorDetails?.message ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
