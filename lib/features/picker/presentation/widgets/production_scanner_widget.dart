import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

class ProductionScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final String? title;
  final String? subtitle;

  const ProductionScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.title,
    this.subtitle,
  });

  @override
  State<ProductionScannerWidget> createState() =>
      _ProductionScannerWidgetState();
}

class _ProductionScannerWidgetState extends State<ProductionScannerWidget>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool _hasPermission = false;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _lastScannedBarcode;
  bool _isConnected = true;

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

      _createController();
    } catch (e) {
      log("❌ Camera permission error: $e");
      _showErrorDialog("Camera permission error: $e");
    }
  }

  void _createController() {
    try {
      // Dispose any existing controller first
      _disposeController();

      controller = MobileScannerController(
        autoStart: false, // Don't auto-start to prevent connection issues
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
        torchEnabled: false,
      );

      setState(() {
        _isInitializing = false;
      });

      log("✅ Production scanner initialized successfully");

      // Start camera after a short delay to ensure stability
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && controller != null) {
          _startCamera();
        }
      });
    } catch (e) {
      log("❌ Controller creation error: $e");
      setState(() {
        _isInitializing = false;
      });
      _showErrorDialog("Failed to create camera controller: $e");
    }
  }

  Future<void> _startCamera() async {
    if (controller == null || !mounted) return;

    try {
      log("📱 Starting camera...");
      await controller!.start();
      log("✅ Camera started successfully");
    } catch (e) {
      log("❌ Error starting camera: $e");
      _showErrorDialog("Failed to start camera: $e");
    }
  }

  void _handleBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || !_isConnected) return;

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
            widget.onBarcodeScanned(scannedBarcode);
          }
          break;
        }
      }
    } catch (e) {
      log("❌ Error processing barcode: $e");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Scanner Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close scanner
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        log("📱 App going to background, stopping camera");
        _isConnected = false;
        try {
          controller?.stop();
        } catch (e) {
          log("❌ Error stopping camera: $e");
        }
        break;
      case AppLifecycleState.resumed:
        log("📱 App resumed, reconnecting camera");
        _isConnected = true;
        if (controller != null && _hasPermission) {
          Future.delayed(Duration(milliseconds: 1000), () {
            if (mounted) {
              _startCamera();
            }
          });
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
              if (controller != null) {
                _startCamera();
              }
            },
            tooltip: 'Reset Scanner',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_hasPermission && controller != null && !_isInitializing)
            MobileScanner(
              controller: controller!,
              onDetect: _handleBarcodeDetected,
              errorBuilder: (context, error) {
                log(
                  "❌ MobileScanner error: ${error.errorCode} - ${error.errorDetails?.message}",
                );
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
          if (_hasPermission && controller != null && !_isInitializing)
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
