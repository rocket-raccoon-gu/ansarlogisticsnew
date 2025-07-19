import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final VoidCallback? onResetScanner;
  final String? title;
  final String? subtitle;

  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.onResetScanner,
    this.title,
    this.subtitle,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _hasPermission = false;
  String? _lastScannedBarcode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcodeDetected(String barcode) {
    // Prevent multiple rapid scans of the same barcode
    if (_isProcessing || _lastScannedBarcode == barcode) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedBarcode = barcode;
    });

    // Stop scanning temporarily
    controller.stop();

    // Call the callback
    widget.onBarcodeScanned(barcode);

    // Reset after a delay to allow for processing
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Resume scanning
        controller.start();
      }
    });

    // Reset the last scanned barcode after a longer delay to allow retry
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastScannedBarcode = null; // Allow retry of the same barcode
        });
      }
    });
  }

  // Method to reset scanner state when API call fails
  void resetScannerState() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastScannedBarcode = null; // Reset to allow retry of same barcode
      });
      // Resume scanning immediately
      controller.start();
    }
    // Call the reset callback if provided
    widget.onResetScanner?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Permission'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app needs camera access to scan barcodes',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Scan Barcode'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
                if (_isScanning) {
                  controller.start();
                } else {
                  controller.stop();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.subtitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(
                widget.subtitle!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 16),
                  Text(
                    'Processing barcode: $_lastScannedBarcode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _handleBarcodeDetected(barcode.rawValue!);
                        break; // Only process the first barcode
                      }
                    }
                  },
                ),
                // Center scan area indicator
                Center(
                  child: Container(
                    width: 250,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;

    // Draw semi-transparent overlay
    canvas.drawRect(Offset.zero & size, paint);

    // Clear the scan area
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 150,
    );

    final clearPaint =
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.clear;

    canvas.drawRect(scanArea, clearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
