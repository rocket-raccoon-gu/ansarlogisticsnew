import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

class TestScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const TestScannerWidget({super.key, required this.onBarcodeScanned});

  @override
  State<TestScannerWidget> createState() => _TestScannerWidgetState();
}

class _TestScannerWidgetState extends State<TestScannerWidget> {
  MobileScannerController? controller;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      // Check if permission is already granted (should be granted during initial permission dialog)
      final status = await Permission.camera.status;
      setState(() {
        _hasPermission = status.isGranted;
      });

      if (!_hasPermission) {
        log(
          "❌ Camera permission not granted - should be granted during initial permission dialog",
        );
        return;
      }

      _createController();
    } catch (e) {
      log("Error initializing scanner: $e");
    }
  }

  void _createController() {
    controller = MobileScannerController(
      autoStart: true,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.all],
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Scanner'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          _hasPermission && controller != null
              ? MobileScanner(
                controller: controller!,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      log("📱 Test scanner detected: ${barcode.rawValue}");
                      widget.onBarcodeScanned(barcode.rawValue!);
                      break;
                    }
                  }
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      _hasPermission
                          ? 'Creating scanner...'
                          : 'Camera permission required',
                      style: TextStyle(fontSize: 16),
                    ),
                    if (!_hasPermission)
                      ElevatedButton(
                        onPressed: _initializeScanner,
                        child: Text('Grant Permission'),
                      ),
                  ],
                ),
              ),
    );
  }
}
