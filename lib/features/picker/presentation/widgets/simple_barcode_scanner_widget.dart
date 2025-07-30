import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

class SimpleBarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final String? title;
  final String? subtitle;

  const SimpleBarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.title,
    this.subtitle,
  });

  @override
  State<SimpleBarcodeScannerWidget> createState() =>
      _SimpleBarcodeScannerWidgetState();
}

class _SimpleBarcodeScannerWidgetState extends State<SimpleBarcodeScannerWidget>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool _hasPermission = false;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

      // Create controller
      controller = MobileScannerController(
        autoStart: true, // Auto-start the camera
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
        torchEnabled: false,
      );

      setState(() {
        _isInitializing = false;
      });

      log("✅ Simple scanner initialized successfully");
    } catch (e) {
      log("❌ Error initializing simple scanner: $e");
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _handleBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    try {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        if (barcode.rawValue != null) {
          final scannedBarcode = barcode.rawValue!;

          // Prevent duplicate scans
          if (scannedBarcode != _lastScannedBarcode) {
            _lastScannedBarcode = scannedBarcode;
            _isProcessing = true;

            log("📱 Barcode detected: $scannedBarcode");
            widget.onBarcodeScanned(scannedBarcode);
          }
          break;
        }
      }
    } catch (e) {
      log("❌ Error processing barcode: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller?.stop();
        break;
      case AppLifecycleState.resumed:
        if (controller != null && _hasPermission) {
          controller!.start();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    log(
      "📱 Scanner build - controller: ${controller != null}, initializing: $_isInitializing, hasPermission: $_hasPermission",
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Scan Barcode'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _lastScannedBarcode = null;
              _isProcessing = false;
              log("📱 Scanner reset");
            },
            tooltip: 'Reset Scanner',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview - Fill entire screen
          if (controller != null && !_isInitializing && _hasPermission)
            SizedBox.expand(
              child: MobileScanner(
                controller: controller!,
                onDetect: _handleBarcodeDetected,
                errorBuilder: (context, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Camera Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          error.errorDetails?.message ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _initializeScanner();
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isInitializing)
                      CircularProgressIndicator(color: Colors.white)
                    else if (!_hasPermission)
                      Icon(Icons.camera_alt, size: 64, color: Colors.red)
                    else
                      Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      _isInitializing
                          ? 'Initializing Scanner...'
                          : !_hasPermission
                          ? 'Camera Permission Required'
                          : 'Scanner Not Ready',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    if (!_isInitializing)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () {
                            _initializeScanner();
                          },
                          child: Text('Retry'),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Overlay UI
          if (controller != null && !_isInitializing && _hasPermission)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.subtitle ?? 'Point camera at barcode',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessing)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Processing barcode...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
