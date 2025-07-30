import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

class StableScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final String? title;
  final String? subtitle;

  const StableScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.title,
    this.subtitle,
  });

  @override
  State<StableScannerWidget> createState() => _StableScannerWidgetState();
}

class _StableScannerWidgetState extends State<StableScannerWidget>
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
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    try {
      if (controller != null) {
        controller!.stop();
        controller!.dispose();
        controller = null;
      }
    } catch (e) {
      log("❌ Error disposing controller: $e");
    }
  }

  Future<void> _initializeScanner() async {
    try {
      // Check if permission is already granted (should be granted during initial permission dialog)
      final status = await Permission.camera.status;

      if (!mounted) return;

      setState(() {
        _hasPermission = status.isGranted;
      });

      if (!_hasPermission) {
        log(
          "❌ Camera permission not granted - should be granted during initial permission dialog",
        );
        // Show a message to the user about enabling camera in settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Camera permission is required for barcode scanning. Please enable it in app settings.',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () async {
                  await openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Create controller with minimal settings
      controller = MobileScannerController(
        autoStart: true,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
        torchEnabled: false,
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      log("✅ Stable scanner initialized successfully");
    } catch (e) {
      log("❌ Error initializing stable scanner: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _handleBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || !mounted) return;

    try {
      final barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        if (barcode.rawValue != null) {
          final scannedBarcode = barcode.rawValue!;

          // Prevent duplicate scans
          if (scannedBarcode != _lastScannedBarcode) {
            _lastScannedBarcode = scannedBarcode;
            _isProcessing = true;

            log("📱 Barcode detected: $scannedBarcode");
            if (mounted) {
              widget.onBarcodeScanned(scannedBarcode);
            }
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
        log("📱 App going to background");
        try {
          controller?.stop();
        } catch (e) {
          log("❌ Error stopping camera: $e");
        }
        break;
      case AppLifecycleState.resumed:
        log("📱 App resumed");
        if (controller != null && _hasPermission) {
          try {
            controller!.start();
          } catch (e) {
            log("❌ Error resuming camera: $e");
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body:
          _hasPermission && controller != null && !_isInitializing
              ? MobileScanner(
                controller: controller!,
                onDetect: _handleBarcodeDetected,
                errorBuilder: (context, error) {
                  log("❌ MobileScanner error: ${error.errorCode}");
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
                            setState(() {
                              _isInitializing = true;
                            });
                            _initializeScanner();
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              )
              : Container(
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
    );
  }
}
