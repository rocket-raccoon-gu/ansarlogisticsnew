import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/di/injector.dart';
import 'dart:developer';

class OptimizedBarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final VoidCallback? onResetScanner;
  final String? title;
  final String? subtitle;

  const OptimizedBarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.onResetScanner,
    this.title,
    this.subtitle,
  });

  @override
  State<OptimizedBarcodeScannerWidget> createState() =>
      _OptimizedBarcodeScannerWidgetState();
}

class _OptimizedBarcodeScannerWidgetState
    extends State<OptimizedBarcodeScannerWidget>
    with WidgetsBindingObserver {
  late BarcodeScannerService _scannerService;
  bool _isInitializing = false;
  bool _isStarting = false;
  bool _isScanning = false;
  String? _lastScannedBarcode;
  bool _isProcessing = false;
  bool _widgetBuilt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerService = getIt<BarcodeScannerService>();
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerService.markAsDetached();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      // Initialize scanner service if not already initialized
      if (!_scannerService.isInitialized) {
        log("🚀 Initializing scanner service...");
        await _scannerService.initialize();
      }

      if (!_scannerService.hasPermission) {
        log("❌ Camera permission not granted");
        _showPermissionError();
        return;
      }

      // Set up barcode listener
      _scannerService.barcodeStream.listen((barcode) {
        _handleBarcodeDetected(barcode);
      });

      // Wait for widget to be built before starting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startScanningAfterWidgetBuilt();
        }
      });
    } catch (e) {
      log("❌ Error initializing scanner: $e");
      _showErrorDialog("Scanner initialization failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _startScanningAfterWidgetBuilt() {
    if (!mounted || _isStarting || _isScanning) return;

    setState(() {
      _widgetBuilt = true;
    });

    // Mark as attached and start scanning
    _scannerService.markAsAttached();

    // Add a small delay to ensure widget is fully built
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _startScanning();
      }
    });
  }

  Future<void> _startScanning() async {
    if (_isStarting || _isScanning) return;

    setState(() {
      _isStarting = true;
    });

    try {
      final success = await _scannerService.startScanning();
      if (success) {
        setState(() {
          _isStarting = false;
          _isScanning = true;
        });
        log("✅ Scanner started successfully");
      } else {
        setState(() {
          _isStarting = false;
        });
        log("❌ Failed to start scanner");
        // Retry after a short delay with multiple attempts
        _retryStartScanning(3);
      }
    } catch (e) {
      setState(() {
        _isStarting = false;
      });
      log("❌ Error starting scanner: $e");
      _retryStartScanning(3);
    }
  }

  void _retryStartScanning(int attempts) {
    if (attempts <= 0 || !mounted) return;

    log("🔄 Retrying scanner start, attempts left: $attempts");
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted && !_isScanning) {
        _startScanning();
      }
    });
  }

  void _handleBarcodeDetected(String barcode) {
    if (_isProcessing || barcode == _lastScannedBarcode) {
      return;
    }

    log("📱 Barcode detected: $barcode");
    _lastScannedBarcode = barcode;
    _isProcessing = true;

    // Pause scanning during processing
    _scannerService.pauseForProcessing();

    // Call the callback
    widget.onBarcodeScanned(barcode);
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.red),
                SizedBox(width: 8),
                Text('Camera Permission Required'),
              ],
            ),
            content: Text(
              'Camera permission is required to scan barcodes. Please grant camera permission in your device settings.',
            ),
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

  void _showErrorDialog(String message) {
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
        // Stop scanning when app goes to background
        _scannerService.stopScanning();
        break;
      case AppLifecycleState.resumed:
        // Resume scanning when app comes back to foreground
        if (_isScanning) {
          _startScanning();
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
          if (_isScanning)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _scannerService.resetForNewSession();
                _lastScannedBarcode = null;
                _isProcessing = false;
              },
              tooltip: 'Reset Scanner',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_scannerService.controller != null && _widgetBuilt)
            MobileScanner(
              controller: _scannerService.controller!,
              onDetect: (capture) {
                // This is handled by the service stream
              },
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
                          _startScanning();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isInitializing || _isStarting)
                    CircularProgressIndicator()
                  else
                    Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    _isInitializing
                        ? 'Initializing Scanner...'
                        : _isStarting
                        ? 'Starting Camera...'
                        : 'Scanner Not Ready',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (!_isInitializing && !_isStarting)
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

          // Overlay UI
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
